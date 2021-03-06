require './lib/dbquery'
require './lib/searchmodule'
require 'wikipedia'

class Artist

  # TODO get artist social media, official site, etc

  def initialize(mbid)
    @artist_data = SearchModule.find("artist", mbid)
    #@artist_data = Musicbrainz_db.find("artist", mbid)
  end

  # Return the MBID of this artist
  def id
    return @artist_data["id"]
  end

  # Returns the name of the artist
  def name
    return @artist_data["name"]
  end

  # Returns artist type "Group", "Person", etc
  def type
    return @artist_data["type"]
  end

  # Returns JSON data representing all release_groups of this artist
  def release_groups
    return @artist_data["release-groups"].sort_by { |hash| hash["first-release-date"]}
  end

  # Get all relation JSON data
  def relations
    return @artist_data["relations"]
  end

  # return the URI of this artist's wikipedia page, if they have one
  def wikipedia
    uri = nil
    @artist_data["relations"].each do |rel|
      if rel["type"] == "wikipedia"
        uri = rel["url"]["resource"]
      end
    end
    return uri
  end

  # If artist.type is "Group", return band member JSON data
  # else, return nil
  def band_members
    if self.type == "Group"
      artist_relations = get_relations(self.relations, "artist")
      hash = {:current => [], :former => []}
      artist_relations.each do |relation|
        if relation["type"] == "member of band" && relation["ended"]
          hash[:former] << relation
        elsif relation["type"] == "member of band" && !relation["ended"]
          hash[:current] << relation
        end
      end
      return hash
    else
      return nil
    end
  end

  # if artist type is "Person", return artist's band's (if they exist)
  def associated_acts
    if self.type == "Person"
      arr = Array.new
      artist_relations = get_relations(self.relations, "artist")
      artist_relations.each do |relation|
        if relation["type"] == "member of band"
          arr << relation
        end
      end
      return arr
    else
      return nil
    end
  end

  def images
    if !(SearchModule.exists_cover_art @artist_data["id"])
      @imgurls = self.images_fetch
      SearchModule.set_cover_art @artist_data["id"], @imgurls
      return @imgurls
    else
      @imgurls = SearchModule.get_cover_art @artist_data["id"]
      return @imgurls
    end
  end

  # Get image urls for this artist from url relations
  # Returns array of image urls
  def images_fetch
    url_relations = get_relations(self.relations, "url")
    @imgurls = []
    url_relations.each do |relation|
      if @imgurls.count < 4
        puts "url relation"
        url = relation["url"]["resource"]
        case relation["type"]
        when "allmusic"
          puts "allmusic"
          begin
            doc = Nokogiri::HTML(open(url,'User-Agent' => 'firefox'))
            # parse for allmusic.com
            if doc.css(".artist-image").count != 0
              imgurl = doc.css(".artist-image").children.css("img").attribute("src").value
              @imgurls << imgurl
            end
          rescue
            puts "skipped"
          end
          puts "exit allmusic"
          # TODO -- can we get all images in lightbox gallery?
        when "bandsintown"
          puts "bandsintown"
          doc = Nokogiri::HTML(open(url))
          if doc.css(".sidebar-image").count != 0
            imgurl = doc.css(".sidebar-image").css("img").attribute("src").value
            @imgurls << imgurl
          end
          puts "exit bandsintown"
        when "last.fm"
          # parse for last.fm
        when "myspace"
          # parse for myspace.com
        when "wikipedia"
          puts "wiki"
          Wikipedia.find(url).image_urls.each do |url|
            # TODO DO NOT PUT SVG FILES HERE
            @imgurls << url unless url.include?(".svg")
          end
          puts "exit wiki"
        end
      end
    end
    puts "images fetch return"
    return @imgurls
  end

  private

  # Get collection of relations of specifc type for Artist
  # @param {Iterable} relations A hash of all relations to sift through
  # @param {String} type The relation type to look for
  def get_relations relations, type
    arr = []
    relations.each do |relation|
      if relation["target-type"] == type
        arr << relation
      end
    end
    return arr
  end

  def open_url url
  end
end
