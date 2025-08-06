#Modified version of EssentialsCompatibility.rb from inori-z.

# ======================================================================
# SUPER TILEMAP VERTICAL WRAPPER THING
#
# This is a little fix for Pokemon Essentials' custom tilemap code
# that works around MKXP's GPU texture size limit that would normally
# stop you from playing a lot of games.
#
# The concept is simple enough: If your tileset is too big, a new
# bitmap will be constructed with all the excess pixels sent to the
# image's right side. This basically means that you now have a limit
# far higher than you should ever actually need.
#
# 1024  -> 4096
# 2048  -> 16384   (enough to get the normal limit)
# 4096  -> 65536   (enough to load pretty much any tileset)
# 8192  -> 262144
# 16384 -> 1048576 (what most people have at this point)
#
# Because of the extra math the game will have to do to find the right
# pixels, this will probably cause a performance hit while on these
# maps which would normally be megasurfaces.
#
# It can probably be improved by changing CustomTilemap.getRegularTile
# to just find the correct pixels on its own, without having to
# translate the coordinates afterwards, but this will satisfy me just
# for the moment.
#
# Really, it'd be far better to cut up the image on the C++ end and
# use a custom shader to get the image right or something like that,
# but that's work for another day.
#
# For now, I'm just happy I can finally test whatever game I like.
#                             ~Zoro
#=======================================================================

module VWrap

  MAX_TEX_SIZE         = Bitmap.max_size
  TILESET_WIDTH        = 0x100
  TILESET_HEIGHT       = MAX_TEX_SIZE - (MAX_TEX_SIZE%32)
  MAX_TEX_SIZE_BOOSTED = MAX_TEX_SIZE**2/TILESET_WIDTH

  def self.clamp(val, min, max)
    val = max if val > max
    val = min if val < min
    return val
  end

  def self.makeVWrappedTileset(originalbmp)
    width = originalbmp.width
    height = originalbmp.height
    if width == TILESET_WIDTH && originalbmp.mega?
      columns = (height / TILESET_HEIGHT.to_f).ceil

      if columns * TILESET_WIDTH > MAX_TEX_SIZE
        raise "Tilemap is too long!\n\nSIZE: #{originalbmp.height}px\nHARDWARE LIMIT: #{MAX_TEX_SIZE}px\nBOOSTED LIMIT: #{MAX_TEX_SIZE_BOOSTED}px"
      end
      bmp = Bitmap.new(TILESET_WIDTH*columns, TILESET_HEIGHT)
      remainder = height % TILESET_HEIGHT

      columns.times{|col|
        srcrect = Rect.new(0, col * TILESET_HEIGHT, width, (col + 1 == columns) ? remainder : TILESET_HEIGHT)
        bmp.blt(col*TILESET_WIDTH, 0, originalbmp, srcrect)
      }
      return bmp
    end

    return originalbmp
  end

  def self.blitVWrappedPixels(destX, destY, dest, src, srcrect)
    if (srcrect.y + srcrect.width < TILESET_HEIGHT)
      # Save the processing power
      return dest.blt(destX, destY, src, srcrect)
    end

    srcrect.x = clamp(srcrect.x, 0,TILESET_WIDTH)
    srcrect.width = clamp(srcrect.width, 0, TILESET_WIDTH - srcrect.x)
    col = (srcrect.y / TILESET_HEIGHT.to_f).floor
    srcX = col * TILESET_WIDTH + srcrect.x
    srcY = srcrect.y % TILESET_HEIGHT

    dest.blt(destX, destY, src, Rect.new(srcX, srcY, srcrect.width, srcrect.height))
  end


end

# -------------------------
if $MKXP == true
  class CustomTilemap
    def tileset=(value)
      if value.mega?
        @tileset = VWrap::makeVWrappedTileset(value)
        value.dispose
      else
        @tileset = value
      end
      @tilesetchanged = true
    end

    def getRegularTile(sprite, id)
      bitmap = @regularTileInfo[id]
      if !bitmap
        bitmap = Bitmap.new(@tileWidth, @tileHeight)
        rect=Rect.new(((id - 384)&7)*@tileSrcWidth,((id - 384)>>3)*@tileSrcHeight,
           @tileSrcWidth,@tileSrcHeight)
           VWrap::blitVWrappedPixels(0,0, bitmap, @tileset, rect)

        @regularTileInfo[id]=bitmap
      end
      sprite.bitmap = bitmap if sprite.bitmap != bitmap
    end

    def repaintAutotiles
      return if $DONTREFRESHAUTOTILES
      for i in 0...@autotileInfo.length
        next if !@autotileInfo[i]
        frame=autotileFrame(i)
        @autotileInfo[i].clear
        bltAutotile(@autotileInfo[i],0,0,i,frame)
      end
    end

    def refreshLayer0(autotiles=false)
      if autotiles
        return true if !shown?
      end
      ptX=@ox-@oxLayer0
      ptY=@oy-@oyLayer0
      if !autotiles && !@firsttime && !@usedsprites &&
        ptX>=0 && ptX+@viewport.rect.width<=@layer0.bitmap.width &&
        ptY>=0 && ptY+@viewport.rect.height<=@layer0.bitmap.height
        if @layer0clip && @viewport.ox==0 && @viewport.oy==0
          @layer0.ox=0
          @layer0.oy=0
          @layer0.src_rect.set(ptX.round,ptY.round,
            @viewport.rect.width,@viewport.rect.height)
        else
          @layer0.ox=ptX.round
          @layer0.oy=ptY.round
          @layer0.src_rect.set(0,0,@layer0.bitmap.width,@layer0.bitmap.height)
        end
        return true
      end
      width=@layer0.bitmap.width
      height=@layer0.bitmap.height
      bitmap=@layer0.bitmap
      ysize=@map_data.ysize
      xsize=@map_data.xsize
      zsize=@map_data.zsize
      twidth=@tileWidth
      theight=@tileHeight
      mapdata=@map_data
      if autotiles
        return true if $DONTREFRESHAUTOTILES
        return true if @fullyrefreshedautos && @prioautotiles.length==0
        xStart=(@oxLayer0/twidth)
        xStart=0 if xStart<0
        yStart=(@oyLayer0/theight)
        yStart=0 if yStart<0
        xEnd=xStart+(width/twidth)+1
        yEnd=yStart+(height/theight)+1
        xEnd=xsize if xEnd>xsize
        yEnd=ysize if yEnd>ysize
        return true if xStart>=xEnd || yStart>=yEnd
        trans=Color.new(0,0,0,0)
        temprect=Rect.new(0,0,0,0)
        tilerect=Rect.new(0,0,twidth,theight)
        zrange=0...zsize
        overallcount=0
        count=0
        if !@fullyrefreshedautos
          for y in yStart..yEnd
            for x in xStart..xEnd
              haveautotile=false
              for z in zrange
                id = mapdata[x, y, z]
                next if !id || id<48 || id>=384
                prioid=@priorities[id]
                next if prioid!=0 || !prioid
                fcount=@framecount[id/48-1]
                next if !fcount || fcount<2
                if !haveautotile
                  haveautotile=true
                  overallcount+=1
                  xpos=(x*twidth)-@oxLayer0
                  ypos=(y*theight)-@oyLayer0
                  bitmap.fill_rect(xpos,ypos,twidth,theight,trans) if overallcount<=2000
                  break
                end
              end
              for z in zrange
                id = mapdata[x,y,z]
                next if !id || id<48
                prioid=@priorities[id]
                next if prioid!=0 || !prioid
                if overallcount>2000
                  xpos=(x*twidth)-@oxLayer0
                  ypos=(y*theight)-@oyLayer0
                  count=addTile(@autosprites,count,xpos,ypos,id)
                  next
                elsif id>=384
                  temprect.set(((id - 384)&7)*@tileSrcWidth,((id - 384)>>3)*@tileSrcHeight,
                    @tileSrcWidth,@tileSrcHeight)
                  xpos=(x*twidth)-@oxLayer0
                  ypos=(y*theight)-@oyLayer0
                  VWrap::blitVWrappedPixels(xpos,ypos, bitmap, @tileset, temprect)
                else
                  tilebitmap=@autotileInfo[id]
                  if !tilebitmap
                    anim=autotileFrame(id)
                    next if anim<0
                    tilebitmap=Bitmap.new(twidth,theight)
                    bltAutotile(tilebitmap,0,0,id,anim)
                    @autotileInfo[id]=tilebitmap
                  end
                  xpos=(x*twidth)-@oxLayer0
                  ypos=(y*theight)-@oyLayer0
                  bitmap.blt(xpos,ypos,tilebitmap,tilerect)
                end
              end
            end
          end
          Graphics.frame_reset
        else
          if !@priorect || !@priorectautos || @priorect[0]!=xStart ||
            @priorect[1]!=yStart ||
            @priorect[2]!=xEnd ||
            @priorect[3]!=yEnd
            @priorectautos=@prioautotiles.find_all{|tile|
              x=tile[0]
              y=tile[1]
              # "next" means "return" here
              next !(x<xStart||x>xEnd||y<yStart||y>yEnd)
            }
            @priorect=[xStart,yStart,xEnd,yEnd]
          end
          for tile in @priorectautos
            x=tile[0]
            y=tile[1]
            overallcount+=1
            xpos=(x*twidth)-@oxLayer0
            ypos=(y*theight)-@oyLayer0
            bitmap.fill_rect(xpos,ypos,twidth,theight,trans)
            z=0
            while z<zsize
              id = mapdata[x,y,z]
              z+=1
              next if !id || id<48
              prioid=@priorities[id]
              next if prioid!=0 || !prioid
              if id>=384
                temprect.set(((id - 384)&7)*@tileSrcWidth,((id - 384)>>3)*@tileSrcHeight,
                  @tileSrcWidth,@tileSrcHeight)
                  VWrap::blitVWrappedPixels(xpos,ypos, bitmap, @tileset, temprect)
              else
                tilebitmap=@autotileInfo[id]
                if !tilebitmap
                  anim=autotileFrame(id)
                  next if anim<0
                  tilebitmap=Bitmap.new(twidth,theight)
                  bltAutotile(tilebitmap,0,0,id,anim)
                  @autotileInfo[id]=tilebitmap
                end
                bitmap.blt(xpos,ypos,tilebitmap,tilerect)
              end
            end
          end
          Graphics.frame_reset if overallcount>500
        end
        @usedsprites=false
        return true
      end
      return false if @usedsprites
      @firsttime=false
      @oxLayer0=@ox-(width>>2)
      @oyLayer0=@oy-(height>>2)
      if @layer0clip
        @layer0.ox=0
        @layer0.oy=0
        @layer0.src_rect.set(width>>2,height>>2,
          @viewport.rect.width,@viewport.rect.height)
      else
        @layer0.ox=(width>>2)
        @layer0.oy=(height>>2)
      end
      @layer0.bitmap.clear
      @oxLayer0=@oxLayer0.floor
      @oyLayer0=@oyLayer0.floor
      xStart=(@oxLayer0/twidth)
      xStart=0 if xStart<0
      yStart=(@oyLayer0/theight)
      yStart=0 if yStart<0
      xEnd=xStart+(width/twidth)+1
      yEnd=yStart+(height/theight)+1
      xEnd=xsize if xEnd>=xsize
      yEnd=ysize if yEnd>=ysize
      if xStart<xEnd && yStart<yEnd
        tmprect=Rect.new(0,0,0,0)
        yrange=yStart...yEnd
        xrange=xStart...xEnd
        for z in 0...zsize
          for y in yrange
            ypos=(y*theight)-@oyLayer0
            for x in xrange
              xpos=(x*twidth)-@oxLayer0
              id = mapdata[x, y, z]
              next if id==0 || @priorities[id]!=0 || !@priorities[id]
              if id>=384
                tmprect.set( ((id - 384)&7)*@tileSrcWidth,((id - 384)>>3)*@tileSrcHeight,
                  @tileSrcWidth,@tileSrcHeight)
                  VWrap::blitVWrappedPixels(xpos,ypos, bitmap, @tileset, tmprect)
              else
                frames=@framecount[id/48-1]
                if frames<=1
                  frame=0
                else
                  frame=(Graphics.frame_count/Animated_Autotiles_Frames)%frames
                end
                bltAutotile(bitmap,xpos,ypos,id,frame)
              end
            end
          end
        end
        Graphics.frame_reset
      end
      return true
    end
  end
end