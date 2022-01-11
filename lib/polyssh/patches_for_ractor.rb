require "tty-table"
Ractor.make_shareable(TTY::Table::Renderer::RENDERER_MAPPER)
Ractor.make_shareable(TTY::Table::Border::Unicode.characters)

require "tty-color"
TTY::Color::ENV = Ractor.make_shareable(ENV.to_h)
TTY::Color.module_eval do
  def output
    $stderr
  end
end

require "pastel"
Pastel::ENV = Ractor.make_shareable(ENV.to_h)
Ractor.make_shareable(Pastel::DecoratorChain.empty)

require "unicode/display_width"
Ractor.make_shareable(Unicode::DisplayWidth::INDEX)

require "unicode_utils"
Ractor.make_shareable(UnicodeUtils::GRAPHEME_CLUSTER_BREAK_MAP)
