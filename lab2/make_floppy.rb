
boot = File.open("boot.bin", "rb").read
kern = File.open("kernel.bin", "rb").read

File.open("floppy.vfd", "wb") do |f|
  f.write boot
  f.write kern
end
