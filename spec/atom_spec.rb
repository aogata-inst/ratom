# encoding: utf-8
# Copyright (c) 2008 The Kaphan Foundation
#
# For licensing information see LICENSE.
#
# Please visit http://www.peerworks.org/contact for further information.
#

require 'spec_helper'
require 'net/http'
require 'time'
require 'property'

shared_examples_for 'simple_single_entry.atom attributes' do
  it "should parse title" do
    expect(@feed.title).to eq('Example Feed')
  end

  it "should parse updated" do
    expect(@feed.updated).to eq(Time.parse('2003-12-13T18:30:02Z'))
  end

  it "should parse id" do
    expect(@feed.id).to eq('urn:uuid:60a76c80-d399-11d9-b93C-0003939e0af6')
  end

  it "should have an entries array" do
    expect(@feed.entries).to be_an_instance_of(Array)
  end

  it "should have one element in the entries array" do
    expect(@feed.entries.size).to eq(1)
  end

  it "should have an alternate" do
    expect(@feed.alternate).not_to be_nil
  end

  it "should have an Atom::Link as the alternate" do
    expect(@feed.alternate).to be_an_instance_of(Atom::Link)
  end

  it "should have the correct href in the alternate" do
    expect(@feed.alternate.href).to eq('http://example.org/')
  end

  it "should have 1 author" do
    expect(@feed.authors.size).to eq(1)
  end

  it "should have 'John Doe' as the author's name" do
    expect(@feed.authors.first.name).to eq("John Doe")
  end

  it "should parse title" do
    expect(@entry.title).to eq('Atom-Powered Robots Run Amok')
  end

  it "should have an alternate" do
    expect(@entry.alternate).not_to be_nil
  end

  it "should have an Atom::Link as the alternate" do
    expect(@entry.alternate).to be_an_instance_of(Atom::Link)
  end

  it "should have the correct href on the alternate" do
    expect(@entry.alternate.href).to eq('http://example.org/2003/12/13/atom03')
  end

  it "should parse id" do
    expect(@entry.id).to eq('urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a')
  end

  it "should parse updated" do
    expect(@entry.updated).to eq(Time.parse('2003-12-13T18:30:02Z'))
  end

  it "should parse summary" do
    expect(@entry.summary).to eq('Some text.')
  end

  it "should parse content" do
    expect(@entry.content).to eq('This <em>is</em> html.')
  end

  it "should parse content type" do
    expect(@entry.content.type).to eq('html')
  end
end

describe Atom do
  describe "Atom::Feed.load_feed" do
    it "should accept an IO" do
      expect { Atom::Feed.load_feed(File.open('spec/fixtures/simple_single_entry.atom')) }.not_to raise_error
    end

    it "should raise ArgumentError with something other than IO or URI" do
      expect { Atom::Feed.load_feed(nil) }.to raise_error(ArgumentError)
    end

    it "should accept a String" do
      expect(Atom::Feed.load_feed(File.read('spec/fixtures/simple_single_entry.atom'))).to be_an_instance_of(Atom::Feed)
    end

    it "should accept a URI" do
      uri = URI.parse('http://example.com/feed.atom')
      response = Net::HTTPSuccess.new(nil, nil, nil)
      allow(response).to receive(:body).and_return(File.read('spec/fixtures/simple_single_entry.atom'))
      mock_http_get(uri, response)

      expect(Atom::Feed.load_feed(uri)).to be_an_instance_of(Atom::Feed)
    end

    it "should accept a URI with query parameters" do
      uri = URI.parse('http://example.com/feed.atom?page=2')
      response = Net::HTTPSuccess.new(nil, nil, nil)
      allow(response).to receive(:body).and_return(File.read('spec/fixtures/simple_single_entry.atom'))
      mock_http_get(uri, response)

      expect(Atom::Feed.load_feed(uri)).to be_an_instance_of(Atom::Feed)
    end

    it "should raise ArgumentError with non-http uri" do
      uri = URI.parse('file:/tmp')
      expect { Atom::Feed.load_feed(uri) }.to raise_error(ArgumentError)
    end

    it "should return an Atom::Feed" do
      feed = Atom::Feed.load_feed(File.open('spec/fixtures/simple_single_entry.atom'))
      expect(feed).to be_an_instance_of(Atom::Feed)
    end

    it "should not raise an error with a String and basic-auth credentials" do
      expect { Atom::Feed.load_feed(File.read('spec/fixtures/simple_single_entry.atom'), :user => 'user', :pass => 'pass') }.not_to raise_error
    end

    it "should not raise an error with a URI with basic-auth credentials" do
      uri = URI.parse('http://example.com/feed.atom')

      response = Net::HTTPSuccess.new(nil, nil, nil)
      allow(response).to receive(:body).and_return(File.read('spec/fixtures/simple_single_entry.atom'))
      mock_http_get(uri, response, 'user', 'pass')

      expect { Atom::Feed.load_feed(uri, :user => 'user', :pass => 'pass') }.not_to raise_error
    end
  end

  describe 'Atom::Entry.load_entry' do
    it "should accept an IO" do
      expect(Atom::Entry.load_entry(File.open('spec/fixtures/entry.atom'))).to be_an_instance_of(Atom::Entry)
    end

    it "should accept a URI" do
      uri = URI.parse('http://example.org/entry.atom')
      response = Net::HTTPSuccess.new(nil, nil, nil)
      allow(response).to receive(:body).and_return(File.read('spec/fixtures/entry.atom'))
      mock_http_get(uri, response)

      expect(Atom::Entry.load_entry(uri)).to be_an_instance_of(Atom::Entry)
    end

    it "should accept a String" do
      expect(Atom::Entry.load_entry(File.read('spec/fixtures/entry.atom'))).to be_an_instance_of(Atom::Entry)
    end

    it "should raise ArgumentError with something other than IO, String or URI" do
      expect { Atom::Entry.load_entry(nil) }.to raise_error(ArgumentError)
    end

    it "should raise ArgumentError with non-http uri" do
      expect { Atom::Entry.load_entry(URI.parse('file:/tmp')) }.to raise_error(ArgumentError)
    end
  end

  describe 'SimpleSingleFeed' do
    before(:all) do
      @feed = Atom::Feed.load_feed(File.open('spec/fixtures/simple_single_entry.atom'))
      @entry = @feed.entries.first
    end

    it_should_behave_like "simple_single_entry.atom attributes"
  end

  describe 'FeedWithStyleSheet' do
    it "should load without failure" do
      expect { feed = Atom::Feed.load_feed(File.open('spec/fixtures/with_stylesheet.atom')) }.not_to raise_error
    end
  end

  describe Atom::Feed do
    it "raises ArgumentError on missing feed tag" do
      expect { Atom::Feed.load_feed("<other>hai</other>") }.to raise_error(ArgumentError, /missing atom:feed/)
    end
  end

  describe 'ComplexFeed' do
    before(:all) do
      @feed = Atom::Feed.load_feed(File.open('spec/fixtures/complex_single_entry.atom'))
    end

    it "should include an xml declaration" do
      expect(@feed.to_xml.to_s).to(match %r{<\?xml version="1.0" encoding="UTF-8"\?>})
    end

    describe Atom::Feed do
      it "should have a title" do
        expect(@feed.title).to eq('dive into mark')
      end

      it "should have type on the title" do
        expect(@feed.title.type).to eq('text')
      end

      it "should have a subtitle" do
        expect(@feed.subtitle).to eq('A <em>lot</em> of effort went into making this effortless')
      end

      it "should have a type for the subtitle" do
        expect(@feed.subtitle.type).to eq('html')
      end

      it "should have an updated date" do
        expect(@feed.updated).to eq(Time.parse('2005-07-31T12:29:29Z'))
      end

      it "should have an id" do
        expect(@feed.id).to eq('tag:example.org,2003:3')
      end

      it "should have 2 links" do
        expect(@feed.links.size).to eq(2)
      end

      it "should have an alternate link" do
        expect(@feed.alternate).not_to be_nil
      end

      it "should have the right url for the alternate" do
        expect(@feed.alternate.to_s).to eq('http://example.org/')
      end

      it "should have a self link" do
        expect(@feed.self).not_to be_nil
      end

      it "should have the right url for self" do
        expect(@feed.self.to_s).to eq('http://example.org/feed.atom')
      end

      it "should have rights" do
        expect(@feed.rights).to eq('Copyright (c) 2003, Mark Pilgrim')
      end

      it "should have a generator" do
        expect(@feed.generator).not_to be_nil
      end

      it "should have a generator uri" do
        expect(@feed.generator.uri).to eq('http://www.example.com/')
      end

      it "should have a generator version" do
        expect(@feed.generator.version).to eq('1.0')
      end

      it "should have a generator name" do
        expect(@feed.generator.name).to eq('Example Toolkit')
      end

      it "should have an entry" do
        expect(@feed.entries.size).to eq(1)
      end

      it "should have a category" do
        expect(@feed.categories.size).to eq(1)
      end
    end

    describe "FeedWithXmlBase" do
      before(:all) do
        @feed = Atom::Feed.load_feed(File.open('spec/conformance/xmlbase.atom'))
      end

      subject { @feed }

      describe '#title' do
        subject { super().title }
        it { is_expected.to eq("xml:base support tests") }
      end
      it 'has 16 entries' do
        expect(subject.entries.size).to eq(16)
      end

      it "should resolve all alternate links to the same location" do
        @feed.entries.each do |entry|
          expect(entry.links.first.href).to eq("http://example.org/tests/base/result.html")
        end
      end

      it "should resolve all links in content to what their label says" do
        skip "support xml:base in content XHTML"
      end
    end

    describe Atom::Entry do
      before(:each) do
        @entry = @feed.entries.first
      end

      it "should have a title" do
        expect(@entry.title).to eq('Atom draft-07 snapshot')
      end

      it "should have an id" do
        expect(@entry.id).to eq('tag:example.org,2003:3.2397')
      end

      it "should have an updated date" do
        expect(@entry.updated).to eq(Time.parse('2005-07-31T12:29:29Z'))
      end

      it "should have a published date" do
        expect(@entry.published).to eq(Time.parse('2003-12-13T08:29:29-04:00'))
      end

      it "should have an author" do
        expect(@entry.authors.size).to eq(1)
      end

      it "should have two links" do
        expect(@entry.links.size).to eq(2)
      end

      it "should have one alternate link" do
        expect(@entry.alternates.size).to eq(1)
      end

      it "should have one enclosure link" do
        expect(@entry.enclosures.size).to eq(1)
      end

      it "should have 2 contributors" do
        expect(@entry.contributors.size).to eq(2)
      end

      it "should have names for the contributors" do
        expect(@entry.contributors[0].name).to eq('Sam Ruby')
        expect(@entry.contributors[1].name).to eq('Joe Gregorio')
      end

      it "should have content" do
        expect(@entry.content).not_to be_nil
      end

      it "should have 2 categories" do
        expect(@entry.categories.size).to eq(2)
      end
    end

    describe Atom::Category do
      describe 'atom category' do
        before(:each) do
          @category = @feed.entries.first.categories.first
        end

        it "should have a term" do
          expect(@category.term).to eq("atom")
        end

        it "should have a scheme" do
          expect(@category.scheme).to eq("http://example.org")
        end

        it "should have a label" do
          expect(@category.label).to eq("Atom")
        end
      end

      describe 'draft category' do
        before(:each) do
          @category = @feed.entries.first.categories.last
        end

        it "should have a term" do
          expect(@category.term).to eq("drafts")
        end

        it "should have a scheme" do
          expect(@category.scheme).to eq("http://example2.org")
        end

        it "should have a label" do
          expect(@category.label).to eq("Drafts")
        end
      end
    end

    describe Atom::Link do
      describe 'alternate link' do
        before(:each) do
          @entry = @feed.entries.first
          @link = @entry.alternate
        end

        it "should have text/html type" do
          expect(@link.type).to eq('text/html')
        end

        it "should have alternate rel" do
          expect(@link.rel).to eq('alternate')
        end

        it "should have href 'http://example.org/2005/04/02/atom'" do
          expect(@link.href).to eq('http://example.org/2005/04/02/atom')
        end

        it "should have 'http://example.org/2005/04/02/atom' string representation" do
          expect(@link.to_s).to eq('http://example.org/2005/04/02/atom')
        end

        it "should have title 'Alternate link'" do
          expect(@link.title).to eq("Alternate link")
        end
      end

      describe 'enclosure link' do
        before(:each) do
          @entry = @feed.entries.first
          @link = @entry.enclosures.first
        end

        it "should have audio/mpeg type" do
          expect(@link.type).to eq('audio/mpeg')
        end

        it "should have enclosure rel" do
          expect(@link.rel).to eq('enclosure')
        end

        it "should have length 1337" do
          expect(@link.length).to eq(1337)
        end

        it "should have href 'http://example.org/audio/ph34r_my_podcast.mp3'" do
          expect(@link.href).to eq('http://example.org/audio/ph34r_my_podcast.mp3')
        end

        it "should have 'http://example.org/audio/ph34r_my_podcast.mp3' string representation" do
          expect(@link.to_s).to eq('http://example.org/audio/ph34r_my_podcast.mp3')
        end
      end
    end

    describe Atom::Person do
      before(:each) do
        @entry = @feed.entries.first
        @person = @entry.authors.first
      end

      it "should have a name" do
        expect(@person.name).to eq('Mark Pilgrim')
      end

      it "should have a uri" do
        expect(@person.uri).to eq('http://example.org/')
      end

      it "should have an email address" do
        expect(@person.email).to eq('f8dy@example.com')
      end
    end

    describe Atom::Content do
      before(:each) do
        @entry = @feed.entries.first
        @content = @entry.content
      end

      it "should have 'xhtml' type" do
        expect(@content.type).to eq('xhtml')
      end

      it "should have 'en' language" do
        expect(@content.xml_lang).to eq('en')
      end

      it "should have the content as the string representation" do
        expect(@content).to eq('<p xmlns="http://www.w3.org/1999/xhtml"><i>[Update: The Atom draft is finished.]</i></p>')
      end
    end
  end

  describe 'ConformanceTests' do
    describe 'nondefaultnamespace.atom' do
      before(:all) do
        @feed = Atom::Feed.load_feed(File.open('spec/conformance/nondefaultnamespace.atom'))
      end

      it "should have a title" do
        expect(@feed.title).to eq('Non-default namespace test')
      end

      it "should have 1 entry" do
        expect(@feed.entries.size).to eq(1)
      end

      describe Atom::Entry do
        before(:all) do
          @entry = @feed.entries.first
        end

        it "should have a title" do
          expect(@entry.title).to eq('If you can read the content of this entry, your aggregator works fine.')
        end

        it "should have content" do
          expect(@entry.content).not_to be_nil
        end

        it "should have 'xhtml' for the type of the content" do
          expect(@entry.content.type).to eq('xhtml')
        end

        it "should strip the outer div of the content" do
          expect(@entry.content).not_to match(/div/)
        end

        it "should keep inner xhtml of content" do
          expect(@entry.content).to eq('<p xmlns="http://www.w3.org/1999/xhtml">For information, see:</p> ' +
  			    '<ul xmlns="http://www.w3.org/1999/xhtml"> ' +
    				 '<li><a href="http://plasmasturm.org/log/376/">Who knows an <abbr title="Extensible Markup Language">XML</abbr> document from a hole in the ground?</a></li> ' +
    				 '<li><a href="http://plasmasturm.org/log/377/">More on Atom aggregator <abbr title="Extensible Markup Language">XML</abbr> namespace conformance tests</a></li> ' +
    				 '<li><a href="http://www.intertwingly.net/wiki/pie/XmlNamespaceConformanceTests"><abbr title="Extensible Markup Language">XML</abbr> Namespace Conformance Tests</a></li> ' +
    			  '</ul>')
  			end
      end
    end

    describe 'unknown-namespace.atom' do
      before(:all) do
        @feed = Atom::Feed.load_feed(File.open('spec/conformance/unknown-namespace.atom'))
        @entry = @feed.entries.first
        @content = @entry.content
      end

      it "should have content" do
        expect(@content).not_to be_nil
      end

      it "should strip surrounding div" do
        expect(@content).not_to match(/div/)
			end

			it "should keep inner lists" do
			  expect(@content).to match(/<h:ul/)
			  expect(@content).to match(/<ul/)
		  end

      it "should have xhtml type" do
        expect(@content.type).to eq('xhtml')
      end
    end

    describe 'linktests.atom' do
      before(:all) do
        @feed = Atom::Feed.load_feed(File.open('spec/conformance/linktests.xml'))
        @entries = @feed.entries
      end

      describe 'linktest1' do
        before(:all) do
          @entry = @entries[0]
        end

        it "should pick single alternate link without rel" do
          expect(@entry.alternate.href).to eq('http://www.snellspace.com/public/linktests/alternate')
        end
      end

      describe 'linktest2' do
        before(:all) do
          @entry = @entries[1]
        end

        it "should be picky about case of alternate rel" do
          expect(@entry.alternate.href).to eq('http://www.snellspace.com/public/linktests/alternate')
        end

        it "should be picky when picking the alternate by type" do
          expect(@entry.alternate('text/plain').href).to eq('http://www.snellspace.com/public/linktests/alternate2')
        end
      end

      describe 'linktest3' do
        before(:all) do
          @entry = @entries[2]
        end

        it "should parse all links" do
          expect(@entry.links.size).to eq(5)
        end

        it "should pick the alternate from a full list of core types" do
          expect(@entry.alternate.href).to eq('http://www.snellspace.com/public/linktests/alternate')
        end
      end

      describe 'linktest4' do
        before(:all) do
          @entry = @entries[3]
        end

        it "should parse all links" do
          expect(@entry.links.size).to eq(6)
        end

        it "should pick the first alternate from a full list of core types with an extra alternate" do
          expect(@entry.alternate.href).to eq('http://www.snellspace.com/public/linktests/alternate')
        end

        it "should pick the alternate by type from a full list of core types with an extra alternate" do
          expect(@entry.alternate('text/plain').href).to eq('http://www.snellspace.com/public/linktests/alternate2')
        end
      end

      describe 'linktest5' do
        before(:all) do
          @entry = @entries[4]
        end

        it "should parse all links" do
          expect(@entry.links.size).to eq(2)
        end

        it "should pick the alternate without choking on a non-core type" do
          expect(@entry.alternate.href).to eq('http://www.snellspace.com/public/linktests/alternate')
        end

        it "should include the non-core type in the list of links" do
          expect(@entry.links.map{|l| l.href }).to include('http://www.snellspace.com/public/linktests/license')
        end
      end

      describe 'linktest6' do
        before(:all) do
          @entry = @entries[5]
        end

        it "should parse all links" do
          expect(@entry.links.size).to eq(2)
        end

        it "should pick the alternate without choking on a non-core type identified by a uri" do
          expect(@entry.alternate.href).to eq('http://www.snellspace.com/public/linktests/alternate')
        end

        it "should include the non-core type in the list of links identified by a uri" do
          expect(@entry.links.map{|l| l.href }).to include('http://www.snellspace.com/public/linktests/example')
        end
      end

      describe 'linktest7' do
        before(:all) do
          @entry = @entries[6]
        end

        it "should parse all links" do
          expect(@entry.links.size).to eq(2)
        end

        it "should pick the alternate without choking on a non-core type" do
          expect(@entry.alternate.href).to eq('http://www.snellspace.com/public/linktests/alternate')
        end

        it "should include the non-core type in the list of links" do
          expect(@entry.links.map{|l| l.href }).to include('http://www.snellspace.com/public/linktests/license')
        end
      end

      describe 'linktest8' do
        before(:all) do
          @entry = @entries[7]
        end

        it "should parse all links" do
          expect(@entry.links.size).to eq(2)
        end

        it "should pick the alternate without choking on a non-core type identified by a uri" do
          expect(@entry.alternate.href).to eq('http://www.snellspace.com/public/linktests/alternate')
        end

        it "should include the non-core type in the list of links identified by a uri" do
          expect(@entry.links.map{|l| l.href }).to include('http://www.snellspace.com/public/linktests/example')
        end
      end

      describe 'linktest9' do
        before(:all) do
          @entry = @entries[8]
        end

        it "should parse all links" do
          expect(@entry.links.size).to eq(3)
        end

        it "should pick the alternate without hreflang" do
          expect(@entry.alternate.href).to eq('http://www.snellspace.com/public/linktests/alternate')
        end
      end
    end

    describe 'ordertest.atom' do
      before(:all) do
        @feed = Atom::Feed.load_feed(File.open('spec/conformance/ordertest.xml'))
      end

      it 'should have 9 entries' do
        expect(@feed.entries.size).to eq(9)
      end

      describe 'ordertest1' do
        before(:each) do
          @entry = @feed.entries[0]
        end

        it "should have the correct title" do
          expect(@entry.title).to eq('Simple order, nothing fancy')
        end
      end

      describe 'ordertest2' do
        before(:each) do
          @entry = @feed.entries[1]
        end

        it "should have the correct title" do
          expect(@entry.title).to eq('Same as the first, only mixed up a bit')
        end
      end

      describe "ordertest3" do
        before(:each) do
          @entry = @feed.entries[2]
        end

        it "should have the correct title" do
          expect(@entry.title).to eq('Multiple alt link elements, which one does your reader show?')
        end

        it "should pick the first alternate" do
          expect(@entry.alternate.href).to eq('http://www.snellspace.com/public/alternate')
        end
      end

      describe 'ordertest4' do
        before(:each) do
          @entry = @feed.entries[3]
        end

        it "should have the correct title" do
          expect(@entry.title).to eq('Multiple link elements, does your feed reader show the "alternate" correctly?')
        end

        it "should pick the right link" do
          expect(@entry.alternate.href).to eq('http://www.snellspace.com/public/alternate')
        end
      end

      describe 'ordertest5' do
        before(:each) do
          @entry = @feed.entries[4]
        end

        it "should have a source" do
          expect(@entry.source).not_to be_nil
        end

        it "should have the correct title" do
          expect(@entry.title).to eq('Entry with a source first')
        end

        it "should have the correct updated" do
          expect(@entry.updated).to eq(Time.parse('2006-01-26T09:20:05Z'))
        end

        it "should have the correct alt link" do
          expect(@entry.alternate.href).to eq('http://www.snellspace.com/public/alternate')
        end

        describe Atom::Source do
          before(:each) do
            @source = @entry.source
          end

          it "should have an id" do
            expect(@source.id).to eq('tag:example.org,2006:atom/conformance/element_order')
          end

          it "should have a title" do
            expect(@source.title).to eq('Order Matters')
          end

          it "should have a subtitle" do
            expect(@source.subtitle).to eq('Testing how feed readers handle the order of entry elements')
          end

          it "should have a updated" do
            expect(@source.updated).to eq(Time.parse('2006-01-26T09:16:00Z'))
          end

          it "should have an author" do
            expect(@source.authors.size).to eq(1)
          end

          it "should have the right name for the author" do
            expect(@source.authors.first.name).to eq('James Snell')
          end

          it "should have 2 links" do
            expect(@source.links.size).to eq(2)
          end

          it "should have an alternate" do
            expect(@source.alternate.href).to eq('http://www.snellspace.com/wp/?p=255')
          end

          it "should have a self" do
            expect(@source.self.href).to eq('http://www.snellspace.com/public/ordertest.xml')
          end
        end
      end

      describe 'ordertest6' do
        before(:each) do
          @entry = @feed.entries[5]
        end

        it "should have a source" do
          expect(@entry.source).not_to be_nil
        end

        it "should have the correct title" do
          expect(@entry.title).to eq('Entry with a source last')
        end

        it "should have the correct updated" do
          expect(@entry.updated).to eq(Time.parse('2006-01-26T09:20:06Z'))
        end

        it "should have the correct alt link" do
          expect(@entry.alternate.href).to eq('http://www.snellspace.com/public/alternate')
        end
      end

      describe 'ordetest7' do
        before(:each) do
          @entry = @feed.entries[6]
        end

        it "should have a source" do
          expect(@entry.source).not_to be_nil
        end

        it "should have the correct title" do
          expect(@entry.title).to eq('Entry with a source in the middle')
        end

        it "should have the correct updated" do
          expect(@entry.updated).to eq(Time.parse('2006-01-26T09:20:07Z'))
        end

        it "should have the correct alt link" do
          expect(@entry.alternate.href).to eq('http://www.snellspace.com/public/alternate')
        end
      end

      describe 'ordertest8' do
        before(:each) do
          @entry = @feed.entries[7]
        end

        it "should have the right title" do
          expect(@entry.title).to eq('Atom elements in an extension element')
        end

        it "should have right id" do
          expect(@entry.id).to eq('tag:example.org,2006:atom/conformance/element_order/8')
        end
      end

      describe 'ordertest9' do
        before(:each) do
          @entry = @feed.entries[8]
        end

        it "should have the right title" do
          expect(@entry.title).to eq('Atom elements in an extension element')
        end

        it 'should have the right id' do
          expect(@entry.id).to eq('tag:example.org,2006:atom/conformance/element_order/9')
        end
      end
    end

    describe 'atom.rng' do

      before(:all) do
        require 'nokogiri'
        rng_schema = File.expand_path("conformance/atom.rng",
                                      File.dirname(__FILE__))
        @schema = Nokogiri::XML::RelaxNG(File.open(rng_schema))
      end

      def validate_against_atom_rng
        expect(@schema.validate(Nokogiri::XML(subject.to_xml.to_s))).to eq([])
      end

      subject do
        Atom::Feed.new do |feed|
          # Order is important
          feed.id = "http://example.test/feed"
          feed.updated = Time.now
          feed.title = 'Test Feed'
          # Add entries
          feed.entries << Atom::Entry.new do |entry|
            entry.id = "http://example.test/entry/1"
            entry.updated = feed.updated
            entry.title = 'Test Entry'
          end
        end
      end

      it 'should validate against a feed without extensions' do
        validate_against_atom_rng
      end

      it 'should validate against a feed with simple extensions' do
        skip 'Does not conform yet - see seangeo/ratom#21'
        # Mark feed as complete
        subject['http://purl.org/syndication/history/1.0', 'complete'] << ''
        validate_against_atom_rng
      end

    end

  end

  describe 'pagination' do
    describe 'first_paged_feed.atom' do
      before(:all) do
        @feed = Atom::Feed.load_feed(File.open('spec/paging/first_paged_feed.atom'))
      end

      it "should be first?" do
        expect(@feed).to be_first
      end

      it "should not be last?" do
        expect(@feed).not_to be_last
      end

      it "should have next" do
        expect(@feed.next_page.href).to eq('http://example.org/index.atom?page=2')
      end

      it "should not have prev" do
        expect(@feed.prev_page).to be_nil
      end

      it "should have last" do
        expect(@feed.last_page.href).to eq('http://example.org/index.atom?page=10')
      end

      it "should have first" do
        expect(@feed.first_page.href).to eq('http://example.org/index.atom')
      end
    end

    describe 'middle_paged_feed.atom' do
      before(:all) do
        @feed = Atom::Feed.load_feed(File.open('spec/paging/middle_paged_feed.atom'))
      end

      it "should not be last?" do
        expect(@feed).not_to be_last
      end

      it "should not be first?" do
        expect(@feed).not_to be_first
      end

      it "should have next_page" do
        expect(@feed.next_page.href).to eq('http://example.org/index.atom?page=4')
      end

      it "should have prev_page" do
        expect(@feed.prev_page.href).to eq('http://example.org/index.atom?page=2')
      end

      it "should have last_page" do
        expect(@feed.last_page.href).to eq('http://example.org/index.atom?page=10')
      end

      it "should have first_page" do
        expect(@feed.first_page.href).to eq('http://example.org/index.atom')
      end
    end

    describe 'last_paged_feed.atom' do
      before(:all) do
        @feed = Atom::Feed.load_feed(File.open('spec/paging/last_paged_feed.atom'))
      end

      it "should not be first?" do
        expect(@feed).not_to be_first
      end

      it "should be last?" do
        expect(@feed).to be_last
      end

      it "should have prev_page" do
        expect(@feed.prev_page.href).to eq('http://example.org/index.atom?page=9')
      end

      it "should not have next_page" do
        expect(@feed.next_page).to be_nil
      end

      it "should have first_page" do
        expect(@feed.first_page.href).to eq('http://example.org/index.atom')
      end

      it "should have last_page" do
        expect(@feed.last_page.href).to eq('http://example.org/index.atom?page=10')
      end
    end

    describe 'pagination using each_entry' do
      before(:each) do
        @feed = Atom::Feed.load_feed(File.open('spec/paging/first_paged_feed.atom'))
      end

      it "should paginate through each entry" do
        feed1 = Atom::Feed.load_feed(File.read('spec/paging/middle_paged_feed.atom'))
        feed2 = Atom::Feed.load_feed(File.read('spec/paging/last_paged_feed.atom'))

        expect(Atom::Feed).to receive(:load_feed).
                  with(URI.parse('http://example.org/index.atom?page=2'), an_instance_of(Hash)).
                  and_return(feed1)
        expect(Atom::Feed).to receive(:load_feed).
                  with(URI.parse('http://example.org/index.atom?page=4'), an_instance_of(Hash)).
                  and_return(feed2)

        entry_count = 0
        @feed.each_entry(:paginate => true) do |entry|
          entry_count += 1
        end

        expect(entry_count).to eq(3)
      end

      it "should not paginate through each entry when paginate not true" do
        entry_count = 0
        @feed.each_entry do |entry|
          entry_count += 1
        end

        expect(entry_count).to eq(1)
      end

      it "should only paginate up to since" do
        response1 = Net::HTTPSuccess.new(nil, nil, nil)
        allow(response1).to receive(:body).and_return(File.read('spec/paging/middle_paged_feed.atom'))
        mock_http_get(URI.parse('http://example.org/index.atom?page=2'), response1)

        entry_count = 0
        @feed.each_entry(:paginate => true, :since => Time.parse('2003-11-19T18:30:02Z')) do |entry|
          entry_count += 1
        end

        expect(entry_count).to eq(1)
      end
    end

    describe "entry_with_simple_extensions.atom" do
      before(:each) do
        @feed = Atom::Feed.load_feed(File.open('spec/fixtures/entry_with_simple_extensions.atom'))
        @entry = @feed.entries.first
      end

      it "should load simple extension for feed" do
        expect(@feed["http://example.org/example", 'simple1']).to eq(['Simple1 Value'])
      end

      it "should load empty simple extension for feed" do
        expect(@feed["http://example.org/example", 'simple-empty']).to eq([''])
      end

      it "should load simple extension 1 for entry" do
        expect(@entry["http://example.org/example", 'simple1']).to eq(['Simple1 Entry Value'])
      end

      it "should load simple extension 2 for entry" do
        expect(@entry["http://example.org/example", 'simple2']).to eq(['Simple2', 'Simple2a'])
      end

      it "should find a simple extension in another namespace" do
        expect(@entry["http://example2.org/example2", 'simple1']).to eq(['Simple Entry Value (NS2)'])
      end

      it "should load simple extension attribute on a category" do
        expect(@entry.categories.first["http://example.org/example", "attribute"].first).to eq("extension")
      end

      it "should write a simple extension attribute as an attribute" do
        expect(@entry.categories.first.to_xml.root['ns1:attribute']).to eq('extension')
      end

      it "should read an extension with the same local name as an Atom element" do
        expect(@feed['http://example.org/example', 'title']).to eq(['Extension Title'])
      end

      it "should find simple extension with dashes in the name" do
        expect(@entry["http://example.org/example", 'simple-with-dash']).to eq(['Simple with dash Value'])
      end

      it_should_behave_like 'simple_single_entry.atom attributes'

      it "should load simple extension 3 xml for entry" do
        expect(@entry["http://example.org/example3", 'simple3']).to eq(['<ContinuityOfCareRecord xmlns="urn:astm-org:CCR">Simple Entry Value (NS2)</ContinuityOfCareRecord>'])
      end

      describe "when only namespace is provided" do
        before :each do
          @example_elements = @entry["http://example.org/example"]
          @example2_elements = @entry['http://example2.org/example2']
          @example3_elements = @entry['http://example.org/example3']
        end

        it "should return namespace elements as a hash" do
          expect(@example_elements).to eq({
            'simple1' => ['Simple1 Entry Value'],
            'simple2' => ['Simple2', 'Simple2a'],
            'simple-with-dash' => ["Simple with dash Value"]
          })

          expect(@example2_elements).to eq({
            'simple1' => ['Simple Entry Value (NS2)']
          })

          expect(@example3_elements).to eq({
            'simple3' => ['<ContinuityOfCareRecord xmlns="urn:astm-org:CCR">Simple Entry Value (NS2)</ContinuityOfCareRecord>']
          })
        end
      end
    end

    describe 'writing simple extensions' do
      it "should recode and re-read a simple extension element" do
        entry = Atom::Entry.new do |entry|
          entry.id = 'urn:test'
          entry.title = 'Simple Ext. Test'
          entry.updated = Time.now
          entry['http://example.org', 'title'] << 'Example title'
        end

        entry2 = Atom::Entry.load_entry(entry.to_xml.to_s)
        expect(entry2['http://example.org', 'title']).to eq(['Example title'])
      end
    end
  end

  describe 'custom_extensions' do
    before(:all) do
      Atom::Entry.add_extension_namespace :ns_alias, "http://custom.namespace"
      Atom::Entry.elements "ns_alias:property", :class => Atom::Extensions::Property
      Atom::Entry.elements "ns_alias:property-with-dash", :class => Atom::Extensions::Property
      @entry = Atom::Entry.load_entry(File.open('spec/fixtures/entry_with_custom_extensions.atom'))
    end

    it "should_load_custom_extensions_for_entry" do
      expect(@entry.ns_alias_property).not_to eq([])
    end

    it "should_load_2_custom_extensions_for_entry" do
      expect(@entry.ns_alias_property.size).to eq(2)
    end

    it "should load correct_data_for_custom_extensions_for_entry" do
      expect(@entry.ns_alias_property.map { |x| [x.name, x.value] }).to eq([['foo', 'bar'], ['baz', 'bat']])
    end
  end

  describe 'custom content type extensions' do
    before(:all) do
      Atom::Content::PARSERS['custom-content-type/xml'] = Atom::Content::Xhtml
      @entry = Atom::Entry.load_entry(File.open('spec/fixtures/entry_with_custom_content_type.atom'))
    end

    it "should parse content by specified content parser" do
      expect(@entry.content).to eq('<changes xmlns="http://www.xxx.com/app"/>')
    end
  end

  describe 'single custom_extensions' do
     before(:all) do
       Atom::Entry.add_extension_namespace :custom, "http://single.custom.namespace"
       Atom::Entry.element "custom:singleproperty", :class => Atom::Extensions::Property
       @entry = Atom::Entry.load_entry(File.open('spec/fixtures/entry_with_single_custom_extension.atom'))
     end

     it "should load single custom extensions for entry" do
       expect(@entry.custom_singleproperty).not_to be_nil
     end

     it "should load correct data for custom extensions for entry" do
       expect(@entry.custom_singleproperty.name).to eq('foo')
       expect(@entry.custom_singleproperty.value).to eq('bar')
     end
   end

  describe 'write_support' do
    # FIXME this example depends on "custom_extensions" for configuring Atom::Entry
    before(:all) do
      @entry = Atom::Entry.new
      @entry.ns_alias_property << Atom::Extensions::Property.new('ratom', 'rocks')
      @entry.ns_alias_property << Atom::Extensions::Property.new('custom extensions', 'also rock')
      @node = @entry.to_xml
    end

    it "should_write_custom_extensions_on_to_xml" do
      expect(@node.root.children.size).to eq(2)
      ratom, custom_extensions = @node.root.children
      expect(ratom.attributes["name"].value).to eq("ratom")
      expect(ratom.attributes["value"].value).to eq("rocks")
      expect(custom_extensions.attributes["name"].value).to eq("custom extensions")
      expect(custom_extensions.attributes["value"].value).to eq("also rock")
    end
  end

  describe Atom::Link do
    before(:each) do
      @href = 'http://example.org/next'
      @link = Atom::Link.new(:rel => 'next', :href => @href)
    end

    it "should fetch feed for fetch_next" do
      expect(Atom::Feed).to receive(:load_feed).with(URI.parse(@href), an_instance_of(Hash))
      @link.fetch
    end

    it "should fetch content when response is not xml" do
      expect(Atom::Feed).to receive(:load_feed).and_raise(ArgumentError)
      response = Net::HTTPSuccess.new(nil, nil, nil)
      allow(response).to receive(:body).and_return('some text.')
      expect(Net::HTTP).to receive(:get_response).with(URI.parse(@href)).and_return(response)
      expect(@link.fetch).to eq('some text.')
    end
  end

  describe Atom::Entry do
    before(:all) do
      @entry = Atom::Entry.load_entry(File.read('spec/fixtures/entry.atom'))
    end

    it "should be == to itself" do
      expect(@entry).to eq(Atom::Entry.load_entry(File.read('spec/fixtures/entry.atom')))
    end

    it "should be != if something changes" do
      @other = Atom::Entry.load_entry(File.read('spec/fixtures/entry.atom'))
      @other.title = 'foo'
      expect(@entry).not_to eq(@other)
    end

    it "should be != if content changes" do
      @other = Atom::Entry.load_entry(File.read('spec/fixtures/entry.atom'))
      @other.content.type = 'html'
      expect(@entry).not_to eq(@other)
    end

    it "should output itself" do
      other = Atom::Entry.load_entry(@entry.to_xml.to_s)
      expect(@entry).to eq(other)
    end

    it "should properly escape titles" do
      @entry.title = "Breaking&nbsp;Space"
      other = Atom::Entry.load_entry(@entry.to_xml.to_s)
      expect(@entry).to eq(other)
    end

    it "should raise error when to_xml'ing non-utf8 content" do
      expect {
        puts(Atom::Entry.new do |entry|
          entry.title = "My entry"
          entry.id = "urn:entry:1"
          entry.content = Atom::Content::Html.new("this is not \227 utf8")
        end.to_xml)
      }.to raise_error(Atom::SerializationError)
    end

    it "should not raise error when to_xml'ing utf8 but non-ascii content" do
      xml = Atom::Entry.new do |entry|
        entry.title = "My entry"
        entry.id = "urn:entry:1"
        entry.content = Atom::Content::Html.new("Žižek is utf8")
      end.to_xml.to_s

      expect(xml).to match(/Žižek/)
    end
  end

  describe 'Atom::Feed initializer' do
    it "should create an empty Feed" do
      expect { Atom::Feed.new }.not_to raise_error
    end

    it "should yield to a block" do
      expect do
        Atom::Feed.new do |f|
          expect(f).to be_an_instance_of(Atom::Feed)
          throw :yielded
        end
      end.to throw_symbol(:yielded)
    end
  end

  describe 'Atom::Entry initializer' do
    it "should create an empty feed" do
      expect { Atom::Entry.new }.not_to raise_error
    end

    it "should yield to a block" do
      expect do
        Atom::Entry.new do |f|
          expect(f).to be_an_instance_of(Atom::Entry)
          throw :yielded
        end
      end.to throw_symbol(:yielded)
    end
  end

  describe Atom::Content::Html do
    it "should escape ampersands in entities" do
      expect(Atom::Content::Html.new("&nbsp;").to_xml.to_s).to eq("<content type=\"html\">&amp;nbsp;</content>")
    end
  end

  describe Atom::Content::Text do
    it "should be createable from a string" do
      txt = Atom::Content::Text.new("This is some text")
      expect(txt).to eq("This is some text")
      expect(txt.type).to eq("text")
    end
  end

  describe Atom::Content::Xhtml do
    it "should be createable from a string" do
      txt = Atom::Content::Xhtml.new("<p>This is some text</p>")
      expect(txt).to eq("<p>This is some text</p>")
      expect(txt.type).to eq("xhtml")
    end

    it "should be renderable to xml" do
      txt = Atom::Content::Xhtml.new("<p>This is some text</p>")
      expect { txt.to_xml }.not_to raise_error
    end
  end

  describe Atom::Content::External do
    before(:each) do
      feed = nil
      expect { feed = Atom::Feed.load_feed(File.open('spec/fixtures/external_content_single_entry.atom')) }.not_to raise_error
      entry = feed.entries.first
      expect(entry.content).not_to be_nil
      @content = entry.content
      expect(@content.class).to eq(Atom::Content::External)
    end

    it "should capture the src" do
      expect(@content.type).to eq('application/pdf')
      expect(@content.src).to eq('http://example.org/pdfs/robots-run-amok.pdf')
    end

    it "should include type and src in the serialized xml" do
      xml = @content.to_xml
      expect(xml['type']).to eq('application/pdf')
      expect(xml['src']).to eq('http://example.org/pdfs/robots-run-amok.pdf')
    end
  end

  describe 'Atom::Category initializer' do
    it "should create a empty category" do
      expect { Atom::Category.new }.not_to raise_error
    end

    it "should create from a hash" do
      category = Atom::Category.new(:term => 'term', :scheme => 'scheme', :label => 'label')
      expect(category.term).to eq('term')
      expect(category.scheme).to eq('scheme')
      expect(category.label).to eq('label')
    end

    it "should create from a block" do
      category = Atom::Category.new do |cat|
        cat.term = 'term'
      end

      expect(category.term).to eq('term')
    end
  end

  describe Atom::Source do
    it "should create an empty source" do
      expect { Atom::Source.new }.not_to raise_error
    end

    it "should create from a hash" do
      source = Atom::Source.new(:title => 'title', :id => 'sourceid')
      expect(source.title).to eq('title')
      expect(source.id).to eq('sourceid')
    end

    it "should create from a block" do
      source = Atom::Source.new do |source|
        source.title = 'title'
        source.id = 'sourceid'
      end
      expect(source.title).to eq('title')
      expect(source.id).to eq('sourceid')
    end
  end

  describe Atom::Generator do
    it "should create an empty generator" do
      expect { Atom::Generator.new }.not_to raise_error
    end

    it "should create from a hash" do
      generator = Atom::Generator.new(:name => 'generator', :uri => 'http://generator')
      expect(generator.name).to eq('generator')
      expect(generator.uri).to eq('http://generator')
    end

    it "should create from a block" do
      generator = Atom::Generator.new do |generator|
        generator.name = 'generator'
        generator.uri = 'http://generator'
      end
      expect(generator.name).to eq('generator')
      expect(generator.uri).to eq('http://generator')
    end

    it "should output the name as the text of the generator element" do
      generator = Atom::Generator.new({:name => "My Generator"})
      expect(generator.to_xml.to_s).to eq("<generator>My Generator</generator>")
    end
  end
end
