local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt

require("luasnip.loaders.from_vscode").lazy_load()

require("luasnip.config").setup({
  history = true,
  updateevents = "TextChanged,TextChangedI",
  enable_autosnippets = true,
  require("luasnip.loaders.from_vscode").lazy_load({paths = { vim.fn.stdpath("config") .. "/snippets/nvim-mjml" },})
})

vim.cmd('autocmd BufRead,BufNewFile *.mjml setfiletype mjml')

vim.keymap.set({"i","s"}, "<Tab>", function()
  if ls.expand_or_jumpable() then
    ls.expand_or_jump()
  end
end, { silent = true }
)

vim.keymap.set({"i", "s"}, "<S-Tab>", function()
  if ls.jumpable(-1) then
    ls.jump(-1)
  end
end, { silent = true }
)

ls.add_snippets("mjml", {
  s("mjml", fmt([[
    <mjml>
      <mj-head>
        {head}
      </mj-head>
      <mj-body>
        {body}
      </mj-body>
    </mjml>
  ]], {
    head = i(1, "<!-- Add head content here -->"),
    body = i(2, "<!-- Add body content here -->"),
  })),

  -- Standard Head Components
  s("mjattributes", fmt([[
    <mj-attributes>
      {attributes}
    </mj-attributes>
  ]], { attributes = i(1, "/* Add attributes here */") })),
  s("mjbreakpoint", fmt([[
    <mj-breakpoint width="{width}" />
  ]], { width = i(1, "600px") })),
  s("mjfont", fmt([[
    <mj-font name="{name}" href="{href}" />
  ]], { name = i(1, "FontName"), href = i(2, "https://font-url.com") })),
  s("mjhtmlattributes", fmt([[
    <mj-html-attributes>
      {attributes}
    </mj-html-attributes>
  ]], { attributes = i(1, "/* Add HTML attributes here */") })),
  s("mjpreview", fmt([[
    <mj-preview>
      {text}
    </mj-preview>
  ]], { text = i(1, "Preview text here") })),
  s("mjstyle", fmt([[
    <mj-style>
      {styles}
    </mj-style>
  ]], { styles = i(1, "/* Add styles here */") })),
  s("mjtitle", fmt([[
    <mj-title>
      {title}
    </mj-title>
  ]], { title = i(1, "Title here") })),

  -- Standard Body Components
  s("mjaccordion", fmt([[
    <mj-accordion>
      {content}
    </mj-accordion>
  ]], { content = i(1, "<!-- Add accordion content here -->") })),
  s("mjbutton", fmt([[
    <mj-button>
      {text}
    </mj-button>
  ]], { text = i(1, "<!-- Add button text here -->") })),
  s("mjcarousel", fmt([[
    <mj-carousel>
      {content}
    </mj-carousel>
  ]], { content = i(1, "<!-- Add carousel content here -->") })),
  s("mjcolumn", fmt([[
    <mj-column width="{width}">
      {content}
    </mj-column>
  ]], { width = i(1, "600px"), content = i(2, "<!-- Add column content here -->") })),
  s("mjdivider", fmt([[
    <mj-divider {attributes} />
  ]], { attributes = i(1, "/* Add divider attributes here */") })),
  s("mjgroup", fmt([[
    <mj-group>
      {content}
    </mj-group>
  ]], { content = i(1, "<!-- Add group content here -->") })),
  s("mjhero", fmt([[
    <mj-hero>
      {content}
    </mj-hero>
  ]], { content = i(1, "<!-- Add hero content here -->") })),
  s("mjimage", fmt([[
    <mj-image src="{src}" alt="{alt}" />
  ]], { src = i(1, "https://image-url.com"), alt = i(2, "Image description") })),
  s("mjnavbar", fmt([[
    <mj-navbar>
      {content}
    </mj-navbar>
  ]], { content = i(1, "<!-- Add navbar content here -->") })),
  s("mjraw", fmt([[
    <mj-raw>
      {content}
    </mj-raw>
  ]], { content = i(1, "<!-- Add raw HTML here -->") })),
  s("mjsection", fmt([[
    <mj-section>
      {content}
    </mj-section>
  ]], { content = i(1, "<!-- Add section content here -->") })),
  s("mjsocial", fmt([[
    <mj-social>
      {content}
    </mj-social>
  ]], { content = i(1, "<!-- Add social content here -->") })),
  s("mjspacer", fmt([[
    <mj-spacer height="{height}" />
  ]], { height = i(1, "20px") })),
  s("mjtable", fmt([[
    <mj-table>
      {content}
    </mj-table>
  ]], { content = i(1, "<!-- Add table content here -->") })),
  s("mjtext", fmt([[
    <mj-text>
      {content}
    </mj-text>
  ]], { content = i(1, "<!-- Add text content here -->") })),
  s("mjwrapper", fmt([[
    <mj-wrapper>
      {content}
    </mj-wrapper>
  ]], { content = i(1, "<!-- Add wrapper content here -->") })),

  -- Ending tags (demonstration of placeholders in ending tags)
  s("mjtextend", fmt([[
    <mj-text>
      {content}
    </mj-text>
  ]], { content = i(1, "<!-- Add text content here -->") })),
  s("mjbuttonend", fmt([[
    <mj-button>
      {text}
    </mj-button>
  ]], { text = i(1, "<!-- Add button text here -->") })),
})
