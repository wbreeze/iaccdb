# assume loaded with rails ActiveRecord
# environment for IAC contest data application

# this class contains methods to find pilots who qualify for stars awards
module IAC
class FindStars
include IAC::Constants

attr_reader :contest, :has_soft_zero, :stars_strict_hz

def initialize(contest_record)
  @contest = contest_record
  @has_soft_zero = @contest.has_soft_zero
  @stars_strict_hz = @contest.year < 2019
end

# Examines the pilots at a contest to find any that qualify for
# stars awards.
# Accepts the database Contest instance for examination
# Returns an Array of Hash, one per stars qualified pilot.
# Each Hash contains:
#  :given_name => first name as a string
#  :family_name => last name as a string
#  :iacID => IAC member number
#  :category => name of category for which qualified as a string
#  :scoresURL => URL to examine the pilot scores
#  :contest => Contest name
#  :date => Contest start date
# Returns an empty array if there are no qualifying pilots
#
# The algorithm is based on the rules for stars qualification from
#   Appendix 5 of the IAC Official Contest Rules
#  foreach category
#    determine number of flights
#    if adequate (one for Pri, Spn; two for Imdt, Adv, Unl)
#    for each pilot
#      for each flight
#        if not three judges, break category (minimum three judges)
#        determine max judges scoring below five (zero if three judges, else one)
#        for each figure
#          count judges scoring below five, break pilot if max exceeded
#        if you get here, the pilot qualified
def self.findStars(contest_record)
  star_finder = FindStars.new(contest_record)
  star_finder.process_for_stars
end

def process_for_stars
  stars = []
  PcResult.where(:contest_id => contest).each do |pc_result|
    pc_result.star_qualifying = false
    pc_result.save!
  end
  Category.all.each do |cat|
    catch (:category) do
      catFlights = cat.flights.where(contest: contest)
      ctFMin = (cat.category =~ /primary|sportsman/i) ? 1 : 2
      if (ctFMin <= catFlights.length) then
        flight = catFlights.first
        catPilots = flight.pilots
        # pilots of first flight sufficient; a pilot must fly every flight
        catPilots.each do |pilot|
          catch (:pilot) do
            catFlights.each do |flight|
              # if not three judges, break category (minimum three judges)
              ctJ = flight.count_judges
              throw :category if ctJ < 3
              maxBlw5 = (ctJ == 3) ? 0 : 1
              pilotFlight = flight.pilot_flights.find_by_pilot_id(pilot)
              throw :pilot if !pilotFlight
              test_pilot_flight(stars, pilotFlight, maxBlw5)
            end # each flight
            stars << { :given_name => pilot.given_name,
                       :family_name => pilot.family_name,
                       :iacID => pilot.iac_id,
                       :category => cat.name,
                       :scoresURL => make_scores_url(pilot, contest),
                       :contest => contest.name,
                       :date => contest.start
                     }
            PcResult.where({ :contest_id => contest, 
                :category_id => cat.id, :pilot_id => pilot }).each do |pc_result|
              pc_result.star_qualifying = true
              pc_result.save!
            end
          end # catch pilot
        end # each pilot
      end # if sufficient flights
    end # catch category
  end # each category
  stars
end

###
private
###

# check score from each judge for each figure 
# throws :pilot if number of scores below five on a figure exceeds maxBlw5
def test_pilot_flight(stars, pilotFlight, max_below_five)
  sa_computer = SaComputer.new(pilotFlight)
  pfScores = if (stars_strict_hz)
    sa_computer.gather_grades(has_soft_zero)
  else
    sa_computer.gather_HZ_adjusted_grades(has_soft_zero)
  end
  pfScores.length.times do |f|
    figure = pfScores[f]
    count_below_five = 0
    figure.length.times do |j|
      grade = figure[j]
      if (0 <= grade && grade < 50) || grade == Constants::HARD_ZERO
        count_below_five += 1 
        throw :pilot if max_below_five < count_below_five
      end
    end
  end
end

# create a URL for the scores
# we don't have ActiveRouting path helpers, so we punt on this
# and build it with extrinsic knowledge of the resource path
def make_scores_url(pilot, contest)
  "http://www.iaccdb.org/pilots/#{pilot.id}/scores/#{contest.id}"
end

end #class
end #module
