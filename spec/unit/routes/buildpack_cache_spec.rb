require 'spec_helper'
require 'securerandom'

module BitsService
  module Routes
    describe BuildpackCache do
      let(:headers) { Hash.new }

      let(:zip_filepath) do
        path = File.join(Dir.mktmpdir, 'some-name.zip')
        TestZip.create(path, 1, 1024)
        path
      end

      let(:zip_file) do
        Rack::Test::UploadedFile.new(File.new(zip_filepath))
      end

      let(:guid) { SecureRandom.uuid }

      let(:upload_body) { { buildpack_cache: zip_file } }

      let(:use_nginx) { false }

      let(:config) do
        {
          buildpack_cache: {
            fog_connection: {
              provider: 'AWS',
              aws_access_key_id: 'fake_aws_key_id',
              aws_secret_access_key: 'fake_secret_access_key'
            }
          },
          nginx: {
            use_nginx: use_nginx
          }
        }
      end

      around(:each) do |example|
        config_filepath = create_config_file(config)
        BitsService::Environment.load_configuration(config_filepath)
        Fog.mock!

        example.run

        Fog.unmock!
        FileUtils.rm_f(config_filepath)
      end

      after(:each) do
        FileUtils.rm_rf(File.dirname(zip_filepath))
      end

      describe 'POST /buildpack_cache' do
        let(:key) { '1234-5678-123456/stackname' }
        before do
          allow_any_instance_of(Helpers::Upload::Params).to receive(:upload_filepath).and_return(zip_filepath)
        end

        it 'returns HTTP status 201' do
          post "/buildpack_cache/#{key}", upload_body, headers
          expect(last_response.status).to eq(201)
        end

        it 'stores the uploaded file in the buildpak_cache blobstore using the correct key' do
          blobstore = double(BitsService::Blobstore::Client)
          expect_any_instance_of(Routes::BuildpackCache).to receive(:buildpack_cache_blobstore).and_return(blobstore)
          expect(blobstore).to receive(:cp_to_blobstore).with(zip_filepath, key)

          post "/buildpack_cache/#{key}", upload_body, headers
        end

        it 'instantiates the upload params decorator with the right arguments' do
          expect(Helpers::Upload::Params).to receive(:new).with(hash_including(
                                                                  'buildpack_cache' => anything
          ), use_nginx: false).once

          post "/buildpack_cache/#{key}", upload_body, headers
        end

        it 'gets the uploaded filepath from the upload params decorator' do
          decorator = double(Helpers::Upload::Params)
          allow(Helpers::Upload::Params).to receive(:new).and_return(decorator)
          expect(decorator).to receive(:upload_filepath).with('buildpack_cache').once
          post "/buildpack_cache/#{key}", upload_body, headers
        end

        it 'does not leave the temporary instance of the uploaded file around' do
          allow_any_instance_of(Helpers::Upload::Params).to receive(:upload_filepath).and_return(zip_filepath)
          post "/buildpack_cache/#{key}", upload_body, headers
          expect(File.exist?(zip_filepath)).to be_falsy
        end

        context 'when no file is being uploaded' do
          before(:each) do
            allow_any_instance_of(Helpers::Upload::Params).to receive(:upload_filepath).and_return(nil)
          end

          it 'returns a corresponding error' do
            expect_any_instance_of(Routes::Buildpacks).to_not receive(:buildpack_blobstore)

            post "/buildpack_cache/#{key}", upload_body, headers

            expect(last_response.status).to eq(400)
            json = JSON.parse(last_response.body)
            expect(json['code']).to eq(290_005)
            expect(json['description']).to match(/a file must be provided/)
          end
        end

        context 'when the blobstore copy fails' do
          before(:each) do
            allow_any_instance_of(Blobstore::Client).to receive(:cp_to_blobstore).and_raise('some error')
          end

          it 'return HTTP status 500' do
            post "/buildpack_cache/#{key}", upload_body, headers
            expect(last_response.status).to eq(500)
          end

          it 'does not leave the temporary instance of the uploaded file around' do
            allow_any_instance_of(Helpers::Upload::Params).to receive(:upload_filepath).and_return(zip_filepath)
            post "/buildpack_cache/#{key}", upload_body, headers
            expect(File.exist?(zip_filepath)).to be_falsy
          end
        end

        context 'when the blobstore helper fails' do
          before(:each) do
            allow_any_instance_of(Routes::BuildpackCache).to receive(:buildpack_cache_blobstore).and_raise('some error')
          end

          it 'return HTTP status 500' do
            post "/buildpack_cache/#{key}", upload_body, headers
            expect(last_response.status).to eq(500)
          end

          it 'does not leave the temporary instance of the uploaded file around' do
            allow_any_instance_of(Helpers::Upload::Params).to receive(:upload_filepath).and_return(zip_filepath)
            post "/buildpack_cache/#{key}", upload_body, headers
            expect(File.exist?(zip_filepath)).to be_falsy
          end
        end
      end
    end
  end
end
