# Copyright (c) 2008 The Kaphan Foundation
#
# For licensing information see LICENSE.
#
# Please visit http://www.peerworks.org/contact for further information.
#
require 'net/https'
require 'time'

RootCA = '/etc/ssl/certs'

# Just a couple methods form transforming strings
unless "".respond_to?(:singularize)
  class String # :nodoc:
    def singularize
      if self =~ /ies$/
        self.sub(/ies$/, 'y')
      else
        self.sub(/s$/, '')
      end
    end
  end
end

unless "".respond_to?(:demodulize)
  class String # :nodoc:
    def demodulize
      self.sub(/.*::/, '')
    end
  end
end

unless "".respond_to?(:constantize)
  class String # :nodoc:
    def constantize
      Object.module_eval("::#{self}", __FILE__, __LINE__)
    end
  end
end

module Atom
  def self.to_attrname(element_name)
    element_name.to_s.sub(/:/, '_').gsub('-', '_').to_sym
  end

  class LoadError < StandardError
    attr_reader :response
    def initialize(response)
      @response = response
    end

    def to_s
      "Atom::LoadError: #{response.code} #{response.message}"
    end
  end

  module Xml # :nodoc:
   class NamespaceHandler
      def initialize(root, default = Atom::NAMESPACE)
        @root = root
        @default = default
        @i = 0
        @map = {}
      end

      def prefix(builder, ns)
        if ns == @default
          builder
        else
          builder[get(ns)]
        end
      end

      def get(ns)
        return @map[ns] if @map[ns]
        prefix = case ns
                   when Atom::NAMESPACE
                     'atom'
                   when Atom::Pub::NAMESPACE
                     'app'
                   else
                     "ns#{@i += 1}"
                 end
        @root.add_namespace_definition(prefix, ns)
        @map[ns] = prefix
        prefix
      end

      def each(&block)
        @map.each(&block)
      end
    end

    module Parseable # :nodoc:
      def parse(xml, options = {})
        starting_depth = xml.depth
        loop do
          case xml.node_type
          when Nokogiri::XML::Reader::TYPE_ELEMENT
            if element_specs.include?(xml.local_name) && (self.class.known_namespaces + [Atom::NAMESPACE, Atom::Pub::NAMESPACE]).include?(xml.namespace_uri)
              element_specs[xml.local_name].parse(self, xml)
            elsif attributes.any? || uri_attributes.any?
              xml.attribute_nodes.each do |node|
                name = [(node.namespace && node.namespace.prefix), node.name].compact.join(':')
                value = node.value
                if attributes.include?(name)
                  # Support attribute names with namespace prefixes
                  self.send("#{accessor_name(name)}=", value)
                elsif uri_attributes.include?(name)
                  value = if xml.base_uri
                    @base_uri = xml.base_uri
                    raw_uri = URI.parse(value)
                    (raw_uri.relative? ? URI.parse(xml.base_uri) + raw_uri : raw_uri).to_s
                  else
                    value
                  end
                  self.send("#{accessor_name(name)}=", value)
                elsif self.respond_to?(:simple_extensions)
                  href = node.namespace && node.namespace.href
                  self[href, node.name].as_attribute = true
                  self[href, node.name] << value
                end
              end
            elsif self.respond_to?(:simple_extensions)
              self[xml.namespace_uri, xml.local_name] << xml.inner_xml
            end
          end
          break unless !options[:once] && xml.read && xml.depth >= starting_depth
        end
      end

      def next_node_is?(xml, element, ns = nil)
        # Get to the next element
        while xml.read && xml.node_type != Nokogiri::XML::Reader::TYPE_ELEMENT; end
        current_node_is?(xml, element, ns)
      rescue Nokogiri::XML::SyntaxError
        false
      end

      def current_node_is?(xml, element, ns = nil)
        xml.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT && xml.local_name == element && (ns.nil? || ns == xml.namespace_uri)
      end

      def accessor_name(name)
        Atom.to_attrname(name)
      end

      def Parseable.included(o)
        o.class_eval do
          def o.ordered_element_specs;  @ordered_element_specs ||= []; end
          def o.element_specs;  @element_specs ||= {}; end
          def o.attributes; @attributes ||= []; end
          def o.uri_attributes; @uri_attributes ||= []; end
          def element_specs; self.class.element_specs; end
          def ordered_element_specs; self.class.ordered_element_specs; end
          def attributes; self.class.attributes; end
          def uri_attributes; self.class.uri_attributes; end
          def o.namespace(ns = @namespace); @namespace = ns; end
          def o.add_extension_namespace(ns, url); self.extensions_namespaces[ns.to_s] = url; end
          def o.extensions_namespaces; @extensions_namespaces ||= {} end
          def o.known_namespaces; @known_namespaces ||= [] end
        end
        o.send(:extend, DeclarationMethods)
      end

      def ==(o)
        if self.object_id == o.object_id
          true
        elsif o.instance_of?(self.class)
          self.class.element_specs.values.all? do |spec|
            self.send(spec.attribute) == o.send(spec.attribute)
          end
        else
          false
        end
      end

      def to_xml(builder = nil, root_name = self.class.name.demodulize.downcase, namespace = nil, namespace_handler = nil)
        orig_builder = builder
        builder ||= Nokogiri::XML::Builder.new

        namespaces = {}
        namespaces['xmlns'] = self.class.namespace if !orig_builder && self.class.respond_to?(:namespace) && self.class.namespace
        self.class.extensions_namespaces.each do |ns_alias,uri|
          namespaces["xmlns:#{ns_alias}"] = uri
        end

        attributes = {}

        node = builder.send("#{root_name}_", namespaces) do |builder|
          namespace_handler ||= NamespaceHandler.new(builder.doc.root, self.class.namespace)

          self.class.ordered_element_specs.each do |spec|
            if spec.single?
              if attribute = self.send(spec.attribute)
                if attribute.respond_to?(:to_xml)
                  attribute.to_xml(builder, spec.name, spec.options[:namespace], namespace_handler)
                else
                  namespaces = {}
                  namespaces['xmlns'] = spec.options[:namespace] if spec.options[:namespace]
                  value = (attribute.is_a?(Time)? attribute.xmlschema : attribute.to_s)
                  builder.send("#{spec.name}_", value, namespaces)
                end
              end
            else
              self.send(spec.attribute).each do |attribute|
                if attribute.respond_to?(:to_xml)
                  attribute.to_xml(builder, spec.name.singularize, nil, namespace_handler)
                else
                  namespaces = {}
                  namespaces['xmlns'] = spec.options[:namespace] if spec.options[:namespace]
                  builder.send("#{spec.name.singularize}_", attribute.to_s, namespaces)
                end
              end
            end
          end
          
          (self.class.attributes + self.class.uri_attributes).each do |attribute|
            if value = self.send(accessor_name(attribute))
              if value != 0
                attributes[attribute] = value.to_s
              end
            end
          end

          if self.respond_to?(:simple_extensions) && self.simple_extensions
            self.simple_extensions.each do |name, value_array|
              if name =~ /\{(.*),(.*)\}/
                value_array.each do |value|
                  if value_array.as_attribute
                    attributes["#{namespace_handler.get($1)}:#{$2}"] = value
                  else
                    namespace_handler.prefix(builder, $1).send("#{$2}_", value)
                  end
                end
              else
                STDERR.print "Couldn't split #{name}"
              end
            end
          end
        end

        attributes.each do |k,v|
          node[k] = v
        end
        
        builder.doc.root
      end

      module DeclarationMethods # :nodoc:
        def element(*names)
          options = {:type => :single}
          options.merge!(names.pop) if names.last.is_a?(Hash)

          names.each do |name|
            attr_accessor Atom.to_attrname(name)
            ns, local_name = name.to_s[/(.*):(.*)/,1], $2 || name
            self.known_namespaces << self.extensions_namespaces[ns] if ns
            self.ordered_element_specs << self.element_specs[local_name.to_s] = ParseSpec.new(name, options)
          end
        end

        def elements(*names)
          options = {:type => :collection}
          options.merge!(names.pop) if names.last.is_a?(Hash)

          names.each do |name|
            name_sym = Atom.to_attrname(name)
            attr_writer name_sym
            define_method name_sym do
              ivar = :"@#{name_sym}"
              self.instance_variable_set ivar, [] unless self.instance_variable_defined? ivar
              self.instance_variable_get ivar
            end
            ns, local_name = name.to_s[/(.*):(.*)/,1], $2 || name
            self.known_namespaces << self.extensions_namespaces[ns] if ns
            self.ordered_element_specs << self.element_specs[local_name.to_s.singularize] = ParseSpec.new(name, options)
          end
        end

        def attribute(*names)
          names.each do |name|
            attr_accessor name.to_s.sub(/:/, '_').to_sym
            self.attributes << name.to_s
          end
        end

        def uri_attribute(*names)
          attr_accessor :base_uri
          names.each do |name|
            attr_accessor name.to_s.sub(/:/, '_').to_sym
            self.uri_attributes << name.to_s
          end
        end

        def loadable!(&error_handler)
          class_name = self.name
          (class << self; self; end).instance_eval do

            define_method "load_#{class_name.demodulize.downcase}" do |*args|
               o = args.first
               opts = args.size > 1 ? args.last : {}

               xml =
                case o
                when String, IO
                  Nokogiri::XML::Reader(o)
                when URI
                  raise ArgumentError, "#{class_name}.load only handles http(s) URIs" unless /http[s]?/ =~ o.scheme
                  response = nil

                  http = http = Net::HTTP.new(o.host, o.port)

                  http.use_ssl = (o.scheme == 'https')
                  if File.directory? RootCA
                    http.ca_path = RootCA
                    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
                    http.verify_depth = 5
                  else
                    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
                  end

                  request = Net::HTTP::Get.new(o.request_uri)
                  if opts[:user] && opts[:pass]
                    request.basic_auth(opts[:user], opts[:pass])
                  elsif opts[:hmac_access_id] && opts[:hmac_secret_key]
                    if Atom::Configuration.auth_hmac_enabled?
                      AuthHMAC.sign!(request, opts[:hmac_access_id], opts[:hmac_secret_key])
                    else
                      raise ArgumentError, "AuthHMAC credentials provides by auth-hmac gem is not installed"
                    end
                  end
                  response = http.request(request)

                  case response
                  when Net::HTTPSuccess
                    Nokogiri::XML::Reader(response.body)
                  when nil
                    raise ArgumentError.new("nil response to #{o}")
                  else
                    raise Atom::LoadError.new(response)
                  end
                else
                  raise ArgumentError, "#{class_name}.load needs String, URI or IO, got #{o.class.name}"
                end

                self.new(xml)
            end
          end
        end

        def parse(xml)
          new(xml)
        end
      end

      # Contains the specification for how an element should be parsed.
      #
      # This should not need to be constructed directly, instead use the
      # element and elements macros in the declaration of the class.
      #
      # See Parseable.
      #
      class ParseSpec # :nodoc:
        attr_reader :name, :options, :attribute

        def initialize(name, options = {})
          @name = name.to_s
          @attribute = Atom.to_attrname(name)
          @options = options
        end

        # Parses a chunk of XML according the specification.
        # The data extracted will be assigned to the target object.
        #
        def parse(target, xml)
          case options[:type]
          when :single
            target.send("#{@attribute}=".to_sym, build(target, xml))
          when :collection
            collection = target.send(@attribute.to_s)
            element    = build(target, xml)
            collection << element
          end
        end

        def single?
          options[:type] == :single
        end

        private
        # Create a member
        def build(target, xml)
          if options[:class].is_a?(Class)
            if options[:content_only]
              options[:class].parse(xml.inner_xml)
            else
              options[:class].parse(xml)
            end
          elsif options[:type] == :single
            xml.read.value
          elsif options[:content_only]
            xml.read.value
          else
            target_class = target.class.name
            target_class = target_class.sub(/#{target_class.demodulize}$/, name.singularize.capitalize)
            target_class.constantize.parse(xml)
          end
        end
      end
    end
  end
end
