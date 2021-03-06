require 'movie_spider'
class Movie
  include Mongoid::Document
  include Mongoid::Timestamps
  field :title, type: String
  field :director,type: String
  field :writer,type: String
  field :actor,type: String
  field :type,type: String
  field :area,type: String
  field :language, type: String
  field :length,type: String,default:'0分钟'
  field :descript,type: String
  field :play_info,type:Hash,default:{tudou:[],youku:[],tecent:[],iqiyi:[]}

  def runing_tudou_tasks
    Task.where(status:Task::ENABLE,site:'土豆',title:self.title).each do |task|
      tudou = MovieSpider::Tudou.new(task.url)
      data  = tudou.start_crawl
      if data.is_a?(Array)
        self.play_info[:tudou] =  data
      elsif data.is_a?(Hash)
        self.play_info[:tudou] << data
      end
      self.save  
    end
  end

  def runing_youku_tasks
    Task.where(status:Task::ENABLE,site:'优酷',title:self.title).each do |task|
      youku = MovieSpider::Youku.new(task.url)
      data  = youku.start_crawl
      if data.is_a?(Array)
        self.play_info[:youku] =  data
      elsif data.is_a?(Hash)
        self.play_info[:youku] << data
      end
      self.save      
    end
  end

  def runing_tecent_tasks
    Task.where(status:Task::ENABLE,site:'腾讯',title:self.title).each do |task|
      qq    = MovieSpider::Qq.new(task.url)
      data  = qq.start_crawl
      if data.is_a?(Array)
        self.play_info[:tecent] =  data
      elsif data.is_a?(Hash)
        self.play_info[:tecent] << data
      end
      self.save 
    end
  end

  def runing_iqiyi_tasks
    Task.where(status:Task::ENABLE,site:'爱奇艺',title:self.title).each do |task|
      iqiyi = MovieSpider::Iqiyi.new(task.url)
      data  = iqiyi.start_crawl
      if data.is_a?(Array)
        self.play_info[:iqiyi] =  data
      elsif data.is_a?(Hash)
        self.play_info[:iqiyi] << data
      end
      self.save    
    end
  end

end