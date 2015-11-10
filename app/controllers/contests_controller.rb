class ContestsController < ApplicationController

  # GET /contests
  def index
    @years = Contest.select("distinct year(start) as anum").all.collect { |contest| contest.anum }
    @years.sort!{|a,b| b <=> a}
    @year = params[:year] || @years.first
    @contests = Contest.where('year(start) = ?', @year).order("start DESC")
  end

  # GET /contests/1
  #   @contest: Contest data record
  #   @categories: array of category_data in category sort order
  #     category_data {}
  #       cat: Category record
  #       judge_results: array of JcResult records in no particular order
  #       flights: array of Flight data records in flight.sequence order
  #       pilot_results: array of pilot results for category
  #            in order ascending overall rank
  #         pilot_result {}
  #           member: Member record for the pilot
  #           overall: PcResult for pilot in contest and category
  #           flight_results: hash of flight results for pilot
  #             key is Flight, value is array of PfResult (with one element)
  def show
    @contest = Contest.find(params[:id])
    flights = @contest.flights
    @categories = []
    if !flights.empty?
      cats = flights.collect { |f| f.category }
      cats = cats.uniq.sort { |a,b| a.sequence <=> b.sequence }
      cats.each do |cat|
        category_data = {}
        category_data[:cat] = cat
        category_data[:judge_results] = JcResult.where(
          contest: @contest, category: cat).includes(:judge)
        category_data[:flights] = Flight.where(contest: @contest,
          category: cat).all
        category_data[:pilot_results] = []
        pc_results = PcResult.where(contest: @contest, category:cat).includes(
          :pilot).order(:category_rank)
        if !pc_results.empty?
          pc_results.all.each do |p|
            pilot_result = {}
            pilot_result[:member] = p.pilot
            pilot_result[:overall] = p
            pilot_result[:flight_results] = {}
            pf_results = PfResult.joins({:pilot_flight => :flight}).where(
               {:pilot_flights => {pilot_id: p.pilot}, 
                :flights => {contest_id: @contest, category_id: cat}})
            pilot_result[:flight_results] = pf_results.all.group_by do |pf|
              pf.flight
            end
            category_data[:pilot_results] << pilot_result
          end
        end
        @categories << category_data
      end
    end
    render :show
  end

end
