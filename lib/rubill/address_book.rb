# $Id$
require 'rubill/application'

class AddressBook < Application
  def initialize group='Billable Clients', address='work', rate_phone="rate"
    @group=group.freeze
    @address=address.freeze
    @appname='Address Book'.freeze
    @rate=rate_phone.freeze
  end

  def address_for_company name
    c=card_for_company(name)
    card=[
      c.name.get[0],
      c.organization.get[0].sub(/ *\{.*\} *$/, '')
    ]
    a=c.addresses[its.label.eq(@address)]
    return card unless a
    [
      card, a.street.get,
      %w(city state zip).collect { |f| a.send(f).get }.select { |f|
        f != :missing_value
      }.join(" ")
    ].flatten.select { |f| f != :missing_value }
  end

  def rate_for_company name
    card_for_company(name).phones[its.label.eq(@rate)].value.get.flatten[0].to_f
  end

  def card_for_company name
    get_app.groups[@group].people[
      its.organization.contains(name)
    ] or raise "Unknown company #{name}"
  end
end
