# Demo priority content for The White House 3.
#
# These are placeholder questions, not factual claims: each entry is the kind of
# ask a citizen would post ("what should government do?"). They are written to
# match the national conversation as of October 2026 so the demo reads as
# current rather than 2012:
#
#   * household electricity bills and the data center build-out
#   * prices and the tariff fight after the IEEPA ruling
#   * Medicaid funding in the federal budget
#   * housing costs, AI rules, and the November midterms
#
# Rewrite or replace this file whenever the demo content goes stale. Both
# db/seeds.rb and `rails wh3:refresh_demo_priorities` read it, so the seed and
# the in-place refresh can never drift apart.
module Wh3Demo
  module Priorities
    # Shown on the homepage and in the browse lists.
    GENERAL = [
      "Cut household energy bills as data centers expand",
      "Lower prices by settling the tariff fight for good",
      "Protect Medicaid funding in the next federal budget",
      "Make housing affordable for first-time buyers",
      "Secure the border and fix legal immigration",
      "Set federal rules for artificial intelligence",
      "Protect election workers and ballot access before November",
      "Stop members of Congress from trading individual stocks",
      "Cap prescription drug costs for every American",
      "Make childcare affordable for working parents"
    ].freeze

    # Tagged priorities. Each issue block needs more than four entries to earn
    # a homepage block (see db/seeds.rb), so keep five per tag.
    ISSUES = {
      "Economy" => [
        "Refund tariffs collected under the struck-down emergency order",
        "Expand the child tax credit for middle-income families",
        "Ban junk fees on tickets, rentals, and utility bills",
        "Index the federal minimum wage to regional costs",
        "Require utilities to disclose what data centers cost ratepayers"
      ],
      "Health Care" => [
        "Let Medicare negotiate prices for all prescription drugs",
        "Keep Medicaid eligibility steady through the next recession",
        "Fund rural hospitals before more of them close",
        "Cap out-of-pocket costs for insulin and inhalers",
        "Expand school-based mental health services"
      ],
      "Energy" => [
        "Make data centers pay for the grid upgrades they need",
        "Speed up permits for new transmission lines",
        "Extend the clean energy tax credit before it lapses",
        "Harden the grid against wildfire and storm outages",
        "Fund next-generation nuclear plants"
      ]
    }.freeze

    # Every name in slot order: the ten general priorities, then each issue
    # block. Used by the refresh task to assign names to existing rows without
    # breaking the endorsements attached to their ids.
    def self.slots
      out = GENERAL.map { |name| [name, nil] }
      ISSUES.each do |tag, names|
        names.each { |name| out << [name, tag] }
      end
      out
    end
  end
end
