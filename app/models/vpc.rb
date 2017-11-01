class Vpc < ApplicationRecord
  acts_as_paranoid
  belongs_to :customer
  has_many :reports

  scope :created_before, -> (from) { where('created <= ?',from) }

  def self.checks
    Pingdom::Check.params={}
    Pingdom::Check.all
  end

  def self.update_from_checks
    updated = 0
    created = 0

    History.write "Updating vpc from checks"

    self.checks.each do |check|

      vpc=self.find_or_create_by id: check.id

      vpc.new_record? ? created+=1 : updated+=1

      vpc.name             = check.name
      vpc.hostname         = check.hostname
      vpc.created          = check.created
      vpc.lasterrortime    = check.lasterrortime
      vpc.lastresponsetime = check.lastresponsetime
      vpc.lasttesttime     = check.lasttesttime
      vpc.resolution       = check.resolution
      vpc.status           = check.status
      vpc.check_type       = check.type
      vpc.data             = { tags: check.tags }.merge(vpc.data || {} ) if check.tags

      unless vpc.customer
        customer = Customer.find_or_create_by name: check.name
        vpc.customer = customer
      end

      vpc.save

    end

    History.write "updated created: #{created}, updated vpcs: #{updated}"

    { total: updated + created, updated: updated, created: created }

  end

  def outages_by_dates from: , to:
    outages.by_dates from, to
  end

end
