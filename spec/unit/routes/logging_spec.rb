require 'spec_helper'


module BitsService
  module Routes
    describe "logging" do
      let(:headers) { Hash.new }

      it 'creates a log entry' do
        expect_any_instance_of(Steno::Logger).to receive(:info).at_least(:twice)
        get '/buildpacks/1234-5678-90', headers
      end

      it 'creates an entry on request start and end' do
        result = {}

        expect_any_instance_of(Steno::Logger).to receive(:info).at_least(:twice) do |logger, event, hash|
          result[event] = hash
        end

        get '/buildpacks/1234-5678-90', headers

        # require 'pry'
        # binding.pry

        expect(result['request.started']).to be
        expect(result['request.started']).to include(:path)
        expect(result['request.started'][:path]).to eq('/buildpacks/1234-5678-90')

        expect(result['request.ended']).to be
      end
    end
  end
end
