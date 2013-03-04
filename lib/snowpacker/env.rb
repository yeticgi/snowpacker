if OS.windows?
  ENV.each do |env, value|
    upper_env = env.upcase
    if env != upper_env && ENV[upper_env]
      ENV[upper_env] = nil
    end
  end
end

