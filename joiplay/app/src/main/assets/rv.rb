
@window = Window.new()
@window.x = 50
@window.y = 50
@window.width = 540
@window.height = 380
@window.opacity = 255
@window.back_opacity = 150
Graphics.update

def drawText(text)
  MKXP.puts(text)
  @window.contents = Bitmap.new(550,40)
  @window.contents.draw_text(0,0,550,20,text,1)
  Graphics.update
end

def read_file(file_name)
  file = File.open(file_name, "r" )
  data = file.read
  file.close
  return data
end

def write_file(data, filename)
  if File.file?(filename)
    File.delete(filename)
  end
  f = File.new(filename, "w")
  f.write(data)
  f.close
end

def deleteDir(dir)
  if File.directory?(dir)
    Dir.foreach(dir) do |file|
      if ((file.to_s != ".") and (file.to_s != ".."))
        deleteDir("#{dir}/#{file}")
      end
    end
    Dir.delete(dir)
  else
    File.delete(dir)
  end
end

def unpack(file)
  tmp = read_file(file)
  tmp = Marshal.load(tmp)
  ext = File.extname(file)
  dir = "Data/UnpackedScripts"#file[0,file.size - ext.size]
  list = ""
  arr = Array.new
  arr.push(ext)
  if File.directory?(dir)
    deleteDir(dir)
    Dir.mkdir(dir)
  else
    Dir.mkdir(dir)
  end
  tmp.each do |a|
    sn = a[1]
    drawText("Unpacking  " + sn)
    sn.force_encoding("UTF-8").gsub!("/","π")
    fn = dir+"/"+ sn + ".rb"
    list = list + sn+"\n"+fn+"\n"
    arr.push(fn)
    data = a[2]
    data = Zlib::Inflate.inflate(data)
    write_file(data, fn.force_encoding("UTF-8"))
  end
  write_file(Marshal.dump(arr), dir+".rbl")
  write_file(list, dir+"/Scripts.list")
  drawText("Unpacking is done.")
end

def pack(file)
  arr = Array.new
  ext = ".rvdata2"
  if File.file?(file+".rbl")
    ary = Marshal.load(read_file(file+".rbl"))
    ext = ary[0]
    ary.each do |f|
      if File.file?(f)
        scname = File.basename(f, ".rb")
        scname.gsub!("π","/")
        drawText("Writing " + scname)
        data = read_file(f)
        data = Zlib::Deflate.deflate(data, Zlib::BEST_COMPRESSION)
        scr = [data.size.to_s, scname, data]
        arr.push(scr)
      end
    end
  else
    drawText("Can not load "+file+".rbl")
    return
  end
  drawText("Packing scripts...")
  tmp = Marshal.dump(arr)
  write_file(tmp, "Data/Scripts"+ext)
  deleteDir(file)
  File.delete(file+".rbl")
  drawText("Scripts are packed.")
end

if File.exists?("Data/UnpackedScripts.rbl")
  pack("Data/UnpackedScripts")
elsif File.exists?("Data/Scripts.rvdata2")
  unpack("Data/Scripts.rvdata2")
elsif File.exists?("Data/Scripts.rvdata")
  unpack("Data/Scripts.rvdata")
elsif File.exists?("Data/Scripts.rxdata")
  unpack("Data/Scripts.rxdata")
else
  drawText("Error : Scripts file is not found.")
end

loop do
  Graphics.update
end