# Change the directionality of a block of CSS code from right-to-left to left-to-right. This includes not only
# altering the <tt>direction</tt> attribute but also altering the 4-argument version of things like <tt>padding</tt>
# to correctly reflect the change. CSS is also minified, in part to make the processing easier.
#
# Author::    Matt Sanford  (mailto:matt@twitter.com)
# Copyright:: Copyright (c) 2011 Twitter, Inc.
# License::   Licensed under the Apache License, Version 2.0
module R2

  # Short cut method for providing a one-time CSS change
  def self.r2(css)
    ::R2::Swapper.new.r2(css)
  end

  # Reuable class for CSS alterations
  class Swapper
    PROPERTY_MAP = {
      'margin-left' => 'margin-right',
      'margin-right' => 'margin-left',

      'padding-left' => 'padding-right',
      'padding-right' => 'padding-left',

      'border-left' => 'border-right',
      'border-right' => 'border-left',

      'border-left-width' => 'border-right-width',
      'border-right-width' => 'border-left-width',

      'border-radius-bottomleft' => 'border-radius-bottomright',
      'border-radius-bottomright' => 'border-radius-bottomleft',
      'border-radius-topleft' => 'border-radius-topright',
      'border-radius-topright' => 'border-radius-topleft',

      '-moz-border-radius-bottomright' => '-moz-border-radius-bottomleft',
      '-moz-border-radius-bottomleft' => '-moz-border-radius-bottomright',
      '-moz-border-radius-topright' => '-moz-border-radius-topleft',
      '-moz-border-radius-topleft' => '-moz-border-radius-topright',

      '-webkit-border-top-right-radius' => '-webkit-border-top-left-radius',
      '-webkit-border-top-left-radius' => '-webkit-border-top-right-radius',
      '-webkit-border-bottom-right-radius' => '-webkit-border-bottom-left-radius',
      '-webkit-border-bottom-left-radius' => '-webkit-border-bottom-right-radius',

      'left' => 'right',
      'right' => 'left'
    }

    VALUE_PROCS = {
      'padding'    => lambda {|obj,val| obj.quad_swap(val) },
      'margin'     => lambda {|obj,val| obj.quad_swap(val) },
      'text-align' => lambda {|obj,val| obj.side_swap(val) },
      'float'      => lambda {|obj,val| obj.side_swap(val) },
      'box-shadow' => lambda {|obj,val| obj.quad_swap(val) },
      '-webkit-box-shadow' => lambda {|obj,val| obj.quad_swap(val) },
      '-moz-box-shadow' => lambda {|obj,val| obj.quad_swap(val) },
      'direction'  => lambda {|obj,val| obj.direction_swap(val) }
    }

    # Given a String of CSS perform the full directionality change
    def r2(original_css)
      css = minimize(original_css)

      result = css.gsub(/([^\{\}]+[^\}]|[\}])+?/) do |rule|
				if rule.match(/[\{\}]/)
					#it is a selector with "{" or a closing "}", insert as it is 
					rule_str = rule
				else
					#It is a decleration	
					rule_str = ""
					rule.split(/;(?!base64)/).each do |decl|
						rule_str << declartion_swap(decl)
					end
				end
        rule_str
      end
      return result
    end

    # Minimize the provided CSS by removing comments, and extra specs
    def minimize(css)
      return '' unless css

      css.gsub(/\/\*[\s\S]+?\*\//, '').   # comments
         gsub(/[\n\r]/, '').              # line breaks and carriage returns
         gsub(/\s*([:;,\{\}])\s*/, '\1'). # space between selectors, declarations, properties and values
         gsub(/\s+/, ' ')                 # replace multiple spaces with single spaces
    end

    # Given a single CSS declaration rule (e.g. <tt>padding-left: 4px</tt>) return the opposing rule (so, <tt>padding-right:4px;</tt> in this example)
    def declartion_swap(decl)
      return '' unless decl

      matched = decl.match(/([^:]+):(.+)$/)
      return '' unless matched

      property = matched[1]
      value = matched[2]

      property = PROPERTY_MAP[property] if PROPERTY_MAP.has_key?(property)
      value = VALUE_PROCS[property].call(self, value) if VALUE_PROCS.has_key?(property)

      return property + ':' + value + ';'
    end

    # Given a value of <tt>rtl</tt> or <tt>ltr</tt> return the opposing value. All other arguments are ignored and returned unmolested.
    def direction_swap(val)
      if val == "rtl"
        "ltr"
      elsif val == "ltr"
        "rtl"
      else
        val
      end
    end

    # Given a value of <tt>right</tt> or <tt>left</tt> return the opposing value. All other arguments are ignored and returned unmolested.
    def side_swap(val)
      if val == "right"
        "left"
      elsif val == "left"
        "right"
      else
        val
      end
    end

    # Given a 4-argument CSS declaration value (like that of <tt>padding</tt> or <tt>margin</tt>) return the opposing
    # value. The opposing value swaps the left and right but not the top or bottom. Any unrecognized argument is returned
    # unmolested (for example, 2-argument values)
    def quad_swap(val)
      # 1px 2px 3px 4px => 1px 4px 3px 2px
      points = val.to_s.split(/\s+/)

      if points && points.length == 4
        [points[0], points[3], points[2], points[1]].join(' ')
      else
        val
      end
    end
  end

end
