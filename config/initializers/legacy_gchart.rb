# Google Image Charts — the API behind the original `gchart` gem — was shut
# down in 2015, so the chart URLs these views generate can no longer resolve.
# This shim returns a neutral placeholder (an inline SVG data URI) wherever the
# views want a chart, so pages render without external calls.
#
# Charting itself is lost functionality: a full replacement needs a modern
# chart library (Chart.js, or a Chart<->Image service) wired into these views.
require 'base64'

module Gchart
  module_function

  def line(options = {})
    placeholder(options)
  end

  def bar(options = {})
    placeholder(options)
  end

  def pie(options = {})
    placeholder(options)
  end

  def line_xy(options = {})
    placeholder(options)
  end

  def placeholder(options = {})
    width, height = size_for(options)
    svg = <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="#{width}" height="#{height}" viewBox="0 0 #{width} #{height}">
        <rect width="100%" height="100%" fill="#EEEEEE"/>
        <text x="50%" y="50%" font-family="sans-serif" font-size="10" fill="#999999"
              text-anchor="middle" dominant-baseline="middle">chart</text>
      </svg>
    SVG
    "data:image/svg+xml;base64,#{Base64.strict_encode64(svg)}"
  end

  def size_for(options)
    width, height = options[:size].to_s.split('x').map(&:to_i)
    width = 150 if width.nil? || width <= 0
    height = 50 if height.nil? || height <= 0
    [width, height]
  end
end
