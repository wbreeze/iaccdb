describe MemberMerge, :type => :services do
  before :example do
    @mr_1 = create(:member)
    @mr_2 = create(:member)
    @merge = MemberMerge.new([@mr_1.id, @mr_2.id])
  end

  it 'finds existing judge pair on judge' do
    j1 = FactoryGirl.create :judge, judge: @mr_1
    j2 = FactoryGirl.create :judge, judge: @mr_2, assist: j1.assist
    score1 = FactoryGirl.create :score, judge:j1
    score2 = FactoryGirl.create :score, judge:j2
    
    expect(@merge.has_overlaps).to eq false
    expect(@merge.has_collisions).to eq false
    @merge.execute_merge(@mr_1)
    
    score1.reload
    expect(score1.judge).to eq j1
    score2.reload
    expect(score2.judge).to eq j1
  end

  it 'finds existing judge pair on assistant' do
    j1 = FactoryGirl.create :judge, assist: @mr_1
    j2 = FactoryGirl.create :judge, assist: @mr_2, judge: j1.judge
    score1 = FactoryGirl.create :score, judge:j1
    score2 = FactoryGirl.create :score, judge:j2
    
    expect(@merge.has_overlaps).to eq false
    expect(@merge.has_collisions).to eq false
    @merge.execute_merge(@mr_1)
    
    score1.reload
    expect(score1.judge).to eq j1
    score2.reload
    expect(score2.judge).to eq j1
  end

  it 'creates needed judge pair on judge' do
    j1 = FactoryGirl.create :judge, judge: @mr_1
    j2 = FactoryGirl.create :judge, judge: @mr_2
    score1 = FactoryGirl.create :score, judge:j1
    score2 = FactoryGirl.create :score, judge:j2
    @merge.execute_merge(@mr_1)
    score1.reload

    expect(@merge.has_overlaps).to eq false
    expect(@merge.has_collisions).to eq false
    expect(score1.judge).to eq j1

    score2.reload
    new_judge = score2.judge
    expect(new_judge).to_not eq j1
    expect(new_judge).to_not eq j2
    expect(new_judge.judge).to eq @mr1
    expect(new_judge.assist).to eq j2.assist
  end

  it 'creates needed judge pair on assistant' do
    j1 = FactoryGirl.create :judge, assist: @mr_1
    j2 = FactoryGirl.create :judge, assist: @mr_2
    score1 = FactoryGirl.create :score, judge:j1
    score2 = FactoryGirl.create :score, judge:j2

    expect(@merge.has_overlaps).to eq false
    expect(@merge.has_collisions).to eq false
    @merge.execute_merge(@mr_1)

    score1.reload
    expect(score1.judge).to eq j1
    score2.reload
    new_judge = score2.judge
    expect(new_judge).to_not eq j1
    expect(new_judge).to_not eq j2
    expect(new_judge.judge).to eq @mr1
    expect(new_judge.assist).to eq j2.assist
  end

  it 'substitutes judge pairs for pfj_results' do
    j1 = FactoryGirl.create :judge, judge: @mr_1
    j2 = FactoryGirl.create :judge, judge: @mr_2
    12.times { FactoryGirl.create :pfj_result, judge:j1 }
    12.times { FactoryGirl.create :pfj_result, judge:j2 }

    judge_pairs = PfjResult.all.collect { |r| r.judge }
    expect(judge_pairs.length).to eq 24
    judges = judge_pairs.collect { |jp| jp.judge }
    judges = judges.uniq
    expect(judges.length).to eq 2
    expect(judges).to include(j1)
    expect(judges).to include(j2)

    expect(@merge.has_overlaps).to eq false
    expect(@merge.has_collisions).to eq false
    @merge.execute_merge(@mr_1)

    judge_pairs = PfjResult.all.collect { |r| r.judge }
    expect(judge_pairs.length).to eq 24
    judges = judge_pairs.collect { |jp| jp.judge }
    judges = judges.uniq
    expect(judges.length).to eq 1
    expect(judges).to include(j1)
    expect(judges).to_not include(j2)
  end

  it 'substitutes judge pairs for jf_results' do
    j1 = FactoryGirl.create :judge, judge: @mr_1
    j2 = FactoryGirl.create :judge, judge: @mr_2
    12.times { FactoryGirl.create :jf_result, judge:j1 }
    12.times { FactoryGirl.create :jf_result, judge:j2 }

    judge_pairs = JfResult.all.collect { |r| r.judge }
    expect(judge_pairs.length).to eq 24
    judges = judge_pairs.collect { |jp| jp.judge }
    judges = judges.uniq
    expect(judges.length).to eq 2
    expect(judges).to include(j1)
    expect(judges).to include(j2)

    expect(@merge.has_overlaps).to eq false
    expect(@merge.has_collisions).to eq false
    @merge.execute_merge(@mr_1)

    judge_pairs = JfResult.all.collect { |r| r.judge }
    expect(judge_pairs.length).to eq 24
    judges = judge_pairs.collect { |jp| jp.judge }
    judges = judges.uniq
    expect(judges.length).to eq 1
    expect(judges).to include(j1)
    expect(judges).to_not include(j2)
  end

  it 'substitutes judge pairs for scores' do
    j1 = FactoryGirl.create :judge, judge: @mr_1
    j2 = FactoryGirl.create :judge, judge: @mr_2
    12.times { FactoryGirl.create :score, judge:j1 }
    12.times { FactoryGirl.create :score, judge:j2 }

    judge_pairs = Score.all.collect { |s| s.judge }
    expect(judge_pairs.length).to eq 24
    judges = judge_pairs.collect { |jp| jp.judge }
    judges = judges.uniq
    expect(judges.length).to eq 2
    expect(judges).to include(j1)
    expect(judges).to include(j2)

    expect(@merge.has_overlaps).to eq false
    expect(@merge.has_collisions).to eq false
    @merge.execute_merge(@mr_1)

    judge_pairs = Score.all.collect { |s| s.judge }
    expect(judge_pairs.length).to eq 24
    judges = judge_pairs.collect { |jp| jp.judge }
    judges = judges.uniq
    expect(judges.length).to eq 1
    expect(judges).to include(j1)
    expect(judges).to_not include(j2)
  end

  it 'removes orphaned judge pairs' do
    j1 = FactoryGirl.create :judge, judge: @mr_1
    j2 = FactoryGirl.create :judge, judge: @mr_2
    j3 = FactoryGirl.create :judge, assist: @mr_1
    j4 = FactoryGirl.create :judge, assist: @mr_2
    4.times do { FactoryGirl.create :score, judge:j1 }
    4.times do { FactoryGirl.create :score, judge:j2 }
    4.times do { FactoryGirl.create :score, judge:j3 }
    4.times do { FactoryGirl.create :score, judge:j4 }

    expect(@merge.has_overlaps).to eq false
    expect(@merge.has_collisions).to eq false
    @merge.execute_merge(@mr_1)

    judges = Judge.all
    expect(judges).not_to include j2
    expect(judges).not_to include j4
    expect(judges).to include j1
    expect(judges).to include j3
  end

  it 'substitutes chief judge for flights' do
    12.times { FactoryGirl.create :flight, chief:@mr_1 }
    12.times { FactoryGirl.create :flight, chief:@mr_2 }

    chief_judges = Flight.all.collect { |f| f.chief }
    expect(chief_judges.length).to eq 24
    chief_judges = chief_judges.uniq
    expect(chief_judges.length).to eq 2
    expect(chief_judges).to include(@mr_1)
    expect(chief_judges).to include(@mr_2)

    expect(@merge.has_overlaps).to eq false
    expect(@merge.has_collisions).to eq false
    @merge.execute_merge(@mr_1)

    chief_judges = Flight.all.collect { |f| f.chief }
    expect(chief_judges.length).to eq 24
    chief_judges = chief_judges.uniq
    expect(chief_judges.length).to eq 1
    expect(chief_judges).to include(@mr_1)
    expect(chief_judges).to_not include(@mr_2)
  end

  it 'substitutes assistant judge for flights' do
    12.times { FactoryGirl.create :flight, assist:@mr_1 }
    12.times { FactoryGirl.create :flight, assist:@mr_2 }

    assist_judges = Flight.all.collect { |f| f.assist }
    expect(assist_judges.length).to eq 24
    assist_judges = assist_judges.uniq
    expect(assist_judges.length).to eq 2
    expect(assist_judges).to include(@mr_1)
    expect(assist_judges).to include(@mr_2)

    expect(@merge.has_overlaps).to eq false
    expect(@merge.has_collisions).to eq false
    @merge.execute_merge(@mr_1)

    assist_judges = Flight.all.collect { |f| f.assist }
    expect(assist_judges.length).to eq 24
    assist_judges = assist_judges.uniq
    expect(assist_judges.length).to eq 1
    expect(assist_judges).to include(@mr_1)
    expect(assist_judges).to_not include(@mr_2)
  end

  it 'substitutes pilot for pilot_flights' do
    12.times { FactoryGirl.create :pilot_flight, pilot:@mr_1 }
    12.times { FactoryGirl.create :pilot_flight, pilot:@mr_2 }

    pilots = PilotFlight.all.collect { |f| f.pilot }
    expect(pilots.length).to eq 24
    pilots = pilots.uniq
    expect(pilots.length).to eq 2
    expect(pilots).to include(@mr_1)
    expect(pilots).to include(@mr_2)

    expect(@merge.has_overlaps).to eq false
    expect(@merge.has_collisions).to eq false
    @merge.execute_merge(@mr_1)

    pilots = PilotFlight.all.collect { |f| f.pilot }
    expect(pilots.length).to eq 24
    pilots = pilots.uniq
    expect(pilots.length).to eq 1
    expect(pilots).to include(@mr_1)
    expect(pilots).to_not include(@mr_2)
  end

  it 'substitutes member for result_members' do
    12.times { FactoryGirl.create :result_member, member:@mr_1 }
    12.times { FactoryGirl.create :result_member, member:@mr_2 }

    members = ResultMember.all.collect { |f| f.member }
    expect(members.length).to eq 24
    members = members.uniq
    expect(members.length).to eq 2
    expect(members).to include(@mr_1)
    expect(members).to include(@mr_2)

    expect(@merge.has_overlaps).to eq false
    expect(@merge.has_collisions).to eq false
    @merge.execute_merge(@mr_1)

    members = ResultMember.all.collect { |f| f.member }
    expect(members.length).to eq 24
    members = members.uniq
    expect(members.length).to eq 1
    expect(members).to include(@mr_1)
    expect(members).to_not include(@mr_2)
  end

  it 'substitutes pilot for result' do
    12.times { FactoryGirl.create :result, pilot:@mr_1 }
    12.times { FactoryGirl.create :result, pilot:@mr_2 }

    pilots = Result.all.collect { |f| f.pilot }
    expect(pilots.length).to eq 24
    pilots = pilots.uniq
    expect(pilots.length).to eq 2
    expect(pilots).to include(@mr_1)
    expect(pilots).to include(@mr_2)

    expect(@merge.has_overlaps).to eq false
    expect(@merge.has_collisions).to eq false
    @merge.execute_merge(@mr_1)

    pilots = Result.all.collect { |f| f.pilot }
    expect(pilots.length).to eq 24
    pilots = pilots.uniq
    expect(pilots.length).to eq 1
    expect(pilots).to include(@mr_1)
    expect(pilots).to_not include(@mr_2)
  end

  it 'substitutes pilot for regional_pilots' do
    12.times { FactoryGirl.create :regional_pilot, pilot:@mr_1 }
    12.times { FactoryGirl.create :regional_pilot, pilot:@mr_2 }

    pilots = RegionalPilot.all.collect { |f| f.pilot }
    expect(pilots.length).to eq 24
    pilots = pilots.uniq
    expect(pilots.length).to eq 2
    expect(pilots).to include(@mr_1)
    expect(pilots).to include(@mr_2)

    expect(@merge.has_overlaps).to eq false
    expect(@merge.has_collisions).to eq false
    @merge.execute_merge(@mr_1)

    pilots = RegionalPilot.all.collect { |f| f.pilot }
    expect(pilots.length).to eq 24
    pilots = pilots.uniq
    expect(pilots.length).to eq 1
    expect(pilots).to include(@mr_1)
    expect(pilots).to_not include(@mr_2)
  end

  it 'substitutes pilot for pc_results' do
    12.times { FactoryGirl.create :pc_result, pilot:@mr_1 }
    12.times { FactoryGirl.create :pc_result, pilot:@mr_2 }

    pilots = PcResult.all.collect { |f| f.pilot }
    expect(pilots.length).to eq 24
    pilots = pilots.uniq
    expect(pilots.length).to eq 2
    expect(pilots).to include(@mr_1)
    expect(pilots).to include(@mr_2)

    expect(@merge.has_overlaps).to eq false
    expect(@merge.has_collisions).to eq false
    @merge.execute_merge(@mr_1)

    pilots = PcResult.all.collect { |f| f.pilot }
    expect(pilots.length).to eq 24
    pilots = pilots.uniq
    expect(pilots.length).to eq 1
    expect(pilots).to include(@mr_1)
    expect(pilots).to_not include(@mr_2)
  end

  it 'substitutes judge for jy_results' do
    12.times { FactoryGirl.create :jy_result, judge:@mr_1 }
    12.times { FactoryGirl.create :jy_result, judge:@mr_2 }

    judges = JyResult.all.collect { |f| f.judge }
    expect(judges.length).to eq 24
    judges = judges.uniq
    expect(judges.length).to eq 2
    expect(judges).to include(@mr_1)
    expect(judges).to include(@mr_2)

    expect(@merge.has_overlaps).to eq false
    expect(@merge.has_collisions).to eq false
    @merge.execute_merge(@mr_1)

    judges = JyResult.all.collect { |f| f.judge }
    expect(judges.length).to eq 24
    judges = judges.uniq
    expect(judges.length).to eq 1
    expect(judges).to include(@mr_1)
    expect(judges).to_not include(@mr_2)
  end

  it 'substitutes judge for jf_results' do
    12.times { FactoryGirl.create :jf_result, judge:@mr_1 }
    12.times { FactoryGirl.create :jf_result, judge:@mr_2 }

    judges = JfResult.all.collect { |f| f.judge }
    expect(judges.length).to eq 24
    judges = judges.uniq
    expect(judges.length).to eq 2
    expect(judges).to include(@mr_1)
    expect(judges).to include(@mr_2)

    expect(@merge.has_overlaps).to eq false
    expect(@merge.has_collisions).to eq false
    expect(@merge.has_collisions).to eq false
    @merge.execute_merge(@mr_1)

    judges = JfResult.all.collect { |f| f.judge }
    expect(judges.length).to eq 24
    judges = judges.uniq
    expect(judges.length).to eq 1
    expect(judges).to include(@mr_1)
    expect(judges).to_not include(@mr_2)
  end

  it 'notifies when two members have the same role on the same flight' do
    pf = FactoryGirl.create :pilot_flight, pilot:@mr_1
    FactoryGirl.create :pilot_flight, pilot:@mr_2, flight: pf.flight

    expect(@merge.has_collisions).to eq true
    flight_collisions = @merge.flight_collisions

    flight_roles = flight_collisions.keys
    expect(flight_roles.length).to eq 1
    rf = flight_roles.first
    expect(rf['role']).to eq 'pilot'
    expect(rf['flight']).to eq pf.flight
    flight = flight_collisions[rf]
    expect(flight).to eq pf.flight
  end

  it 'notifies when two members have different roles on the same flight' do
    pf = FactoryGirl.create :pilot_flight, pilot:@mr_1
    jp = FactoryGirl.create :judge, judge:@mr_2
    score = FactoryGirl.create :score, judge: jp, pilot_flight: pf

    expect(@merge.has_overlaps).to eq true
    flight_overlaps = @merge.flight_overlaps

    flights = flight_overlaps.keys
    expect(flights.length).to eq 1
    flight = flights.first
    expect(flight).to eq pf.flight
    roles = flight_overlaps[flight]
    expect(roles.include?('pilot')).to eq true
    expect(roles.include?('judge')).to eq true
  end

  context 'well connected members' do
    before :example do
      j = FactoryGirl.create :judge, judge: @mr_1
      FactoryGirl.create :score, judge:j
      j = FactoryGirl.create :judge, judge: @mr_2
      FactoryGirl.create :score, judge:j
      j = FactoryGirl.create :judge, assist: @mr_1
      FactoryGirl.create :score, judge:j
      j = FactoryGirl.create :judge, assist: @mr_2
      FactoryGirl.create :score, judge:j
      j = FactoryGirl.create :judge, judge: @mr_1
      FactoryGirl.create(:pfj_result, judge:j)
      j = FactoryGirl.create :judge, judge: @mr_2
      FactoryGirl.create(:pfj_result, judge:j)
      j = FactoryGirl.create :judge, judge: @mr_1
      FactoryGirl.create(:jf_result, judge:j)
      j = FactoryGirl.create :judge, judge: @mr_2
      FactoryGirl.create(:jf_result, judge:j)
      j = FactoryGirl.create :judge, judge: @mr_1
      FactoryGirl.create(:score, judge:j)
      j = FactoryGirl.create :judge, judge: @mr_2
      FactoryGirl.create(:score, judge:j)
      FactoryGirl.create :flight, chief:@mr_1
      FactoryGirl.create :flight, chief:@mr_2
      FactoryGirl.create :flight, assist:@mr_1
      FactoryGirl.create :flight, assist:@mr_2
      FactoryGirl.create :pilot_flight, pilot:@mr_1
      FactoryGirl.create :pilot_flight, pilot:@mr_2
      FactoryGirl.create :result_member, member:@mr_1
      FactoryGirl.create :result_member, member:@mr_2
      FactoryGirl.create :result, pilot:@mr_1
      FactoryGirl.create :result, pilot:@mr_2
      FactoryGirl.create :regional_pilot, pilot:@mr_1
      FactoryGirl.create :regional_pilot, pilot:@mr_2
      FactoryGirl.create :pc_result, pilot:@mr_1
      FactoryGirl.create :pc_result, pilot:@mr_2
      FactoryGirl.create :jy_result, judge:@mr_1
      FactoryGirl.create :jy_result, judge:@mr_2
      FactoryGirl.create :jf_result, judge:@mr_1
      FactoryGirl.create :jf_result, judge:@mr_2
      expect(@merge.has_overlaps).to eq false
      expect(@merge.has_collisions).to eq false
    end

    it 'orphans the merged members' do
      @merge.execute_merge(@mr_1)
    end

    it 'removes the merged members' do
      @merge.execute_merge(@mr_1)
      expect(Member.find(@mr_2.id)).to raise RecordNotFound
      expect(Member.find(@mr_1.id)).to match_array([@mr_1])
    end
  end
end
