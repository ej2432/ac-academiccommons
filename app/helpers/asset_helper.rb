module AssetHelper
  def player(document, brand_link)
    caption_link = captions_download_url(document['cul_doi_ssi']) if document.captions?
    if document.audio?
      audio_player document.wowza_media_url(request), brand_link, caption_link
    elsif document.video?
      video_player document.wowza_media_url(request), document.image_url(768), brand_link, caption_link
    else
      tag.div 'Not a playable asset'
    end
  end

  def video_player(url, poster_path, brand_link, caption_link)
    tag.div class: 'mediaelement-player' do
      tag.video style: 'position: absolute; top: 0; left: 0;', poster: poster_path, controls: 'controls', preload: 'none', data: { brand_link: brand_link } do
        source_element(url, caption_link)
      end
    end
  end

  def audio_player(url, brand_link, caption_link)
    tag.div class: 'mediaelement-player' do
      tag.audio width: 1024, controls: 'controls', preload: 'none', data: { brand_link: brand_link } do
        source_element(url, caption_link)
      end
    end
  end

  def source_element(url, caption_link)
    src = tag.source(type: 'application/x-mpegURL', src: url)
    src.concat(tag.track(label: 'English', kind: 'subtitles', srclang: 'en', src: caption_link)) if caption_link
    src
  end
end
