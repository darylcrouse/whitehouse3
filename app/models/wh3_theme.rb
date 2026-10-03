# Applies the WhiteHouse 3 design palette (from docs/wh3-concept) to the
# government's ColorScheme. The scheme backs the inline per-page CSS rendered
# by color_schemes/_scheme_css, so re-tinting it updates links, buttons, nav,
# boxes and status colors consistently across the whole app.
#
# Called from db/seeds.rb (demo bootstrap). Idempotent: re-running re-applies
# the same values.
class Wh3Theme
  PALETTE = {
    # type & ink
    'heading'                 => '1b3c5a',
    'sub_heading'             => '6f5a36',  # bronze section labels
    'text'                    => '5f727d',
    'greyed_out'              => '8b98a3',
    'link'                    => '1b3c5a',
    'fonts'                   => 'Montserrat, Helvetica Neue, Arial, sans-serif',

    # surfaces
    'background'              => 'f1f0ee',  # page wash (#backgroundwrap)
    'main'                    => 'FFFFFF',  # content card
    'box'                     => 'f1f0ee',
    'box_text'                => '5f727d',
    'footer'                  => 'f1f0ee',  # body bg; #footer_container re-toned to navy in wh3.css
    'footer_text'             => '5f727d',
    'border'                  => 'd9d3c6',

    # nav
    'nav_background'          => 'ffffff',
    'nav_text'                => '1b3c5a',
    'nav_selected_background' => 'ffffff',
    'nav_selected_text'       => '0f2a45',
    'nav_hover_background'    => 'f1f0ee',
    'nav_hover_text'          => '0f2a45',

    # controls
    'input'                   => 'ffffff',
    'action_button'           => 'c6af8a',
    'action_button_border'    => 'a88f61',
    'action_button_text'      => '0f2a45',
    'grey_button'             => 'ffffff',
    'grey_button_border'      => 'd9d3c6',
    'grey_button_text'        => '1b3c5a',

    # vote states (design: endorse = navy, oppose = bronze)
    'endorsed_button'         => '1b3c5a',
    'endorsed_button_text'    => 'ffffff',
    'opposed_button'          => '6f5a36',
    'opposed_button_text'     => 'ffffff',
    'compromised_button'      => 'a88f61',
    'compromised_button_text' => 'ffffff',
    'up'                      => '2c4e6d',
    'down'                    => '6f5a36',

    # notices
    'error'                   => 'a03d2e',
    'error_text'              => 'ffffff',
    'comments'                => 'f1f0ee',
    'comments_text'           => '5f727d'
  }.freeze

  def self.apply!(scheme = Government.current&.color_scheme)
    return nil unless scheme

    updates = PALETTE.select { |k, v| scheme[k] != v }
    if updates.any?
      scheme.update_columns(updates)
      scheme.clear_cache
    end
    scheme
  end
end
