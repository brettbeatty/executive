# Used by "mix format"
locals_without_parens = [
  option: 2,
  option: 3,
  option_type: 1,
  option_type: 2,
  options_type: 1,
  options_type: 2,
  with_schema: 1
]

[
  export: [
    locals_without_parens: locals_without_parens
  ],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens
]
