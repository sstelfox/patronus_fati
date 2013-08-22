
module PatronusFati
  SERVER_RESPONSE = %r{
    (?<header> [A-Z]+){0}
    (?<data> .+){0}

    ^\*\g<header>:\s+\g<data>$
  }x

  SERVER_DATA = %r{
    (?<string> \S+){0}
    (?<string_with_space> \x01(\S+\b?){0,}\x01){0}

    (\g<string_with_space>|\g<string>)
  }x
end
