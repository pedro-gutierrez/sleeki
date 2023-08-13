locals_without_parens = [
  allow: 1,
  allow: 2,
  attribute: 2,
  attribute: 3,
  entity: 1,
  meta: 1,
  link: 1,
  primary_key: 2,
  slot: 1,
  roles: 1,
  schema: 1,
  scope: 2,
  title: 1,
  unique: 1,
  view: 1
]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]
