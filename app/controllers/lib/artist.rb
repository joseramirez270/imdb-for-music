require './lib/dbquery'

class Artist

  # TODO get artist social media, official site, etc

  def initialize(mbid)
    @artist_data = Musicbrainz_db.find("artist", mbid)
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

  # Get image urls for this artist from url relations
  # Returns array of image urls
  def images
    url_relations = get_relations(self.relations, "url")
    imgurls = []
    url_relations.each do |relation|
      puts "url relation"
      url = relation["url"]["resource"]
      case relation["type"]
      when "allmusic"
        doc = Nokogiri::HTML(open(url))
        # parse for allmusic.com
        if doc.css(".artist-image").count != 0
          imgurl = doc.css(".artist-image").children.css("img").attribute("src").value
          imgurls << imgurl
        end
        # TODO -- can we get all images in lightbox gallery?
      when "bandsintown"
        doc = Nokogiri::HTML(open(url))
        if doc.css(".sidebar-image").count != 0
          imgurl = doc.css(".sidebar-image").css("img").attribute("src").value
          imgurls << imgurl
        end
      when "discogs"
        doc = Nokogiri::HTML(open(url))
        # parse for discogs.com
        gallery_url = ""
        if doc.css(".image_gallery_more").count != 0
          gallery_url = "https://www.discogs.com" +
                      doc.css(".image_gallery_more").children.css("a").attribute("href").value
        elsif doc.css(".image_gallery").count != 0
          gallery_url = "https://www.discogs.com" +
                      doc.css(".image_gallery").css("a").attribute("href").value
        end

        if gallery_url != ""
          doc = Nokogiri::HTML(open(gallery_url))
          gallery = doc.css('[id="view_images"]').children.css("p")
          i = 0
          gallery.each do |element|
            if (element.children.css("img").count != 0)
              puts "in discogs" + i.to_s
              imgurl = element.css("img").attribute("src").value
              imgurls << imgurl
              puts imgurls
            end
            i = i + 1
          end
        end
      when "last.fm"
        # parse for last.fm
      when "myspace"
        # parse for myspace.com
      when "wikipedia"
        # parse for wikipedia
      end
    end

    return imgurls
    # TODO check for duplicate images, maybe use phasion https://github.com/westonplatter/phashion
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

end