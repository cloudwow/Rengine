module Rengine
  class StaticFileManager

    def self.upload_weblabs_css
      Rengine::Weblab.find(:all).each do |weblab|
        gzip_upload(weblab.stylesheet,"text/css; charset=utf-8" ,"stylesheets/#{weblab.id}")
      end
    end

    def self.gzip_upload(content,content_type,remote_path)


      if remote_path.index("/")==0
        remote_path=remote_path.slice(1..-1)
      end
      strio = StringIO.open('', 'w')
      gz = Zlib::GzipWriter.new(strio)
      gz.write(content)
      gz.close
      puts "GZIP uploading #{$cdn_bucket}/#{remote_path} #{content_type}"
      NotRelational::RepositoryFactory.instance.storage.put($cdn_bucket,remote_path,(strio.string),{'Content-Type' => content_type ,'x-amz-acl'=>'public-read',"Content-Encoding" => 'gzip','Expires'=>"Thu, 01 Dec 2020 16:00:00 GMT"})
    end
    def upload(content,content_type,remote_path)
      if remote_path.index("/")==0
        remote_path=remote_path.slice(1..-1)
      end

      puts "uploading #{$cdn_bucket}/#{remote_path} #{content_type}"

      NotRelational::RepositoryFactory.instance.storage.put($cdn_bucket,remote_path,content,{'Content-Type' => content_type ,'x-amz-acl'=>'public-read','Expires'=>"Thu, 01 Dec 2020 16:00:00 GMT"})
    end

  end


end
