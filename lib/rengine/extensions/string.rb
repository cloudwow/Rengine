class String
  def to_user
    User.find(self.downcase)
  end
  
  def escape
        return self.gsub(/[']/, '\\\\\'')

  end
end
