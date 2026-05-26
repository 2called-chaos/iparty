# IParty

## Exceptions

These are the exceptions you might encounter using this gem. Only IParty exceptions are added by this gem, the other ones are for your reference.

```ruby
StandardError
  SystemCallError
    Errno::*
  ArgumentError
    IPAddr::Error
      IPAddr::AddressFamilyError
      IPAddr::InvalidAddressError
        IPAddr::InvalidPrefixError
  IParty::Error
    IParty::MaxMind::Database::Error
      IParty::MaxMind::Database::InvalidFileFormatError
```

IParty::Address will generally raise IPAddr exceptions.
To guard against IP errors, if you do not already rescue broader, you typically want to rescue IPAddr::Error and IParty::Error.
