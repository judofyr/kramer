Gem::Specification.new do |s|
  s.name        = 'kramer'
  s.version     = '0.0.1'
  s.summary     = 'Generalized parser combinators in Ruby'
  s.description = 'Generalized parser combinators in Ruby'
  s.author      = 'Magnus Holm'
  s.email       = 'judofyr@gmail.com'
  s.homepage    = 'https://github.com/judofyr/kramer'
  s.files       = `git ls-files`.split("\n")
  s.test_files  = `git ls-files -- test/*`.split("\n")

  s.add_dependency 'hamster'
end