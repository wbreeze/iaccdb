json.pilot_flight_data do
  json.(@pilot_flight, :id, :penalty_total, :hors_concours, :chapter)
  json.pilot do
    json.(@pilot_flight.pilot, :id, :name, :iac_id)
  end
  json.airplane do
    json.partial! 'airplanes/airplane', airplane: @pilot_flight.airplane
  end
  json.flight do
    json.partial! 'flight', flight: @pilot_flight.flight
  end
  json.grades do
    json.partial! 'score', collection: @pilot_flight.scores, :as => :score
  end
  json.sequence do
    json.partial! 'jf_results/sequence', sequence: @pilot_flight.sequence
  end
end