require 'image_science'

module Rengine
  module Imager
    

    def download(url)

      
      url=url.gsub(" ","%20")
      result=nil

      begin
        Nanikore::Retry.retryable(:tries => 2){

          open(url, "User-Agent" => 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
               "Referer" => "http://www.google.com/search?aq=f&sourceid=chrome&ie=UTF-8&q=duh") { |f|
            result = f.read
          }
        }
      rescue Exception => e
        puts e.to_s
        result=nil
      end
      return result
    end

    def get_image_size(url)

      #cache sizes to avoid downloading same image over and over
      @@size_cache ||={}

      return @@size_cache[url] if @@size_cache.has_key?(url)
      image_data=download(url)

      result=nil
      if image_data
        begin
          ImageScience.with_image_from_memory(image_data) do |pic|
            result= pic.width,pic.height
          end
        rescue Exception
        end

      else
      end

      @@size_cache[url]=result
      return result;
    end

    def resize_image(image_data,product_id,maxwidth,maxheight,maintain_aspect_ratio=true,enlarge_ok=false)
      

      ImageScience.with_image_from_memory(image_data) do |pic|
        
        imgwidth = pic.width
        imgheight = pic.height
        new_pic=nil
        
        if imgwidth<maxwidth and imgheight<maxheight and !enlarge_ok
          return nil,nil,nil
        end

        new_width=-1
        new_height=-1
        if maintain_aspect_ratio
          
          aspectratio = maxwidth.to_f / maxheight.to_f
          imgratio = imgwidth.to_f / imgheight.to_f
          imgratio > aspectratio ? scaleratio = maxwidth.to_f / imgwidth : scaleratio = maxheight.to_f / imgheight

          new_width=imgwidth*scaleratio
          new_height=imgheight*scaleratio
          
        else

          new_width=maxwidth
          new_height=maxheight
        end 
        new_key=nil
        
        pic.resize(new_width,new_height) do |new_pic|
          new_key=save_pic(new_pic,:key=>product_id)
        end
        return new_key,new_width.to_i,new_height.to_i
        
      end
    end
    
    def from_file_to_storage(filepath,options={})
      with_pic_from_file(filepath){|pic|
        save_pic(pic,options)
      }

    end
    
    def save_pic(pic,options={})
      mime_type=options[:mime_type] || 'image/jpeg'
      image_data=pic_to_blob(pic)
      bucket=options[:bucket] || $cdn_bucket
      key=options[:key] || "images/#{UUID.generate(:compact)}/#{pic.width}x#{pic.height}"
      NotRelational::RepositoryFactory.instance.storage.real_s3_put(
                                                                    bucket,
                                                                    key,
                                                                    image_data,
                                                                    {'Content-Type' => mime_type,'x-amz-acl'=>'public-read','Expires'=>"Thu, 01 Dec 2025 16:00:00 GMT"})


      return "http://"+bucket+"/"+key
    end

    def with_pic_from_file(filepath)

      ImageScience.with_image(filepath){|pic|
        yield pic
      }
      
      
    end
    
    def pic_to_blob(pic)
      temp_filename="/mnt/temp_pic_file_#{rand(100000)}"
      pic.save(temp_filename)

      begin
        return open(temp_filename, "rb") {|io| io.read }
      ensure
        File.delete(temp_filename)
      end
    end


  end
end
