def spinner
  chars = ['|', '/', '-', '\\']
  20.times do
    print chars.rotate!.first
    sleep(0.1)
    print "\b"
  end
end

spinner
