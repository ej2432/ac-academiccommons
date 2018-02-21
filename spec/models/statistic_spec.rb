require 'rails_helper'

RSpec.describe Statistic, type: :model do

  describe '.merge_stats' do
    before :each do
      FactoryBot.create_list(:view_stat, 2)
      FactoryBot.create(:download_stat, identifier: 'actest:1')
      FactoryBot.create(:view_stat, identifier: 'ac:duplicate')
      FactoryBot.create(:download_stat, identifier: 'ac:duplicate')
    end

    it 'merges statistics correctly' do
      expect(Statistic.where(identifier: 'ac:duplicate').count).to be 2
      expect(Statistic.where(identifier: 'actest:1').count).to be 3
      Statistic.merge_stats('actest:1', 'ac:duplicate')
      expect(Statistic.where(identifier: 'actest:1').count).to be 5
      expect(Statistic.where(identifier: 'ac:duplicate').count).to be 0
    end
  end

  describe '.event_count' do
    it 'checks event param' do
      expect {
        Statistic.event_count('actest:1', 'foo')
      }.to raise_error "event must one of #{Statistic::EVENTS}"
    end

    it 'checks asset_pids' do
      expect {
        Statistic.event_count(1, 'foo')
      }.to raise_error 'pids must be an Array or String'
    end

    context 'when query is not limited by date' do
      it 'returns correct counts' do
        FactoryBot.create_list(:view_stat, 3, identifier: 'actest:1')
        FactoryBot.create(:view_stat, identifier: 'actest:2')
        expect(
          Statistic.event_count(['actest:1', 'actest:2', 'actest:3'], Statistic::VIEW)
        ).to match('actest:1' => 3, 'actest:2' => 1)
      end
    end

    context 'when query is limited by date' do
      before :each do
        FactoryBot.create(:view_stat, at_time: Time.local(2015, 12, 31, 23, 0))
        FactoryBot.create(:view_stat, at_time: Time.local(2015, 1, 1))
        FactoryBot.create(:view_stat, at_time: Time.local(2015, 1, 31, 23, 0))
        FactoryBot.create(:view_stat, at_time: Time.local(2015, 1, 21, 4, 0))
        FactoryBot.create(:view_stat, at_time: Time.local(2015, 2, 1))
        FactoryBot.create(:view_stat, identifier: 'actest:2', at_time: Time.local(2015, 12, 5))
      end

      it 'returns correct counts for Jan 2015' do
        expect(
          Statistic.event_count('actest:1', Statistic::VIEW, start_date: Date.civil(2015, 1), end_date: Date.civil(2015, 1, -1))
        ).to match('actest:1' => 3)
      end

      it 'returns correct counts for Feb 2015' do
        expect(
          Statistic.event_count('actest:1', Statistic::VIEW, start_date: Date.civil(2015, 2), end_date: Date.civil(2015, 2, -1))
        ).to match('actest:1' => 1)
      end

      it 'returns correct counts for Dec 2015' do
        expect(
          Statistic.event_count(['actest:1', 'actest:2'], Statistic::VIEW, start_date: Date.civil(2015, 12), end_date: Date.civil(2015, 12, -1))
        ).to match('actest:1' => 1, 'actest:2' => 1)
      end
    end
  end
end
