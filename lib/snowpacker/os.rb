module OS
  def self.windows?
    (RUBY_PLATFORM =~ /cygwin|mswin|mingw|bccwin|wince|emx/) != nil
  end

  def self.mac?
    (RUBY_PLATFORM =~ /darwin/) != nil
  end

  def self.unix?
    !windows?
  end

  def self.linux?
    unix? && !mac?
  end

  def self.cygpath(win_path)
    `cygpath -u "#{win_path}"`.chomp
  end
end

