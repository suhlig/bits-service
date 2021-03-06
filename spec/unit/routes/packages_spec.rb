require 'spec_helper'

module BitsService
  module Routes
    describe Packages do
      let(:blobstore) { double(Blobstore::Client) }
      let(:headers) { Hash.new }
      before do
        allow_any_instance_of(Routes::Packages).to receive(:packages_blobstore).and_return(blobstore)
      end

      describe 'POST /packages' do
        let(:package_guid) { SecureRandom.uuid }
        let(:zip_filepath) { '/path/to/zip/file' }
        let(:request_body) { { application: 'something' } }
        let(:package_response) { { 'guid' => package_guid }  }

        before do
          allow(SecureRandom).to receive(:uuid).and_return(package_guid)
          allow_any_instance_of(Helpers::Upload::Params).to receive(:upload_filepath).and_return(zip_filepath)
          allow(blobstore).to receive(:cp_to_blobstore)
          allow(FileUtils).to receive(:rm_r)
        end

        it 'returns HTTP status 201' do
          post '/packages', request_body, headers
          expect(last_response.status).to eq(201)
        end

        it 'an guid for the stored package' do
          post '/packages', request_body, headers
          response_body = last_response.body
          expect(response_body).to_not be_empty

          json = JSON.parse(last_response.body)
          expect(json).to_not be_empty
          expect(json['guid']).to eq(package_guid)
        end

        context 'when the upload_filepath is empty' do
          before(:each) do
            allow_any_instance_of(Helpers::Upload::Params).to receive(:upload_filepath).and_return('')
          end

          it 'returns HTTP status 400' do
            post '/packages', request_body, headers
            expect(last_response.status).to eq(400)
          end

          it 'returns a corresponding error' do
            post '/packages', request_body, headers
            json = JSON.parse(last_response.body)
            expect(json['description']).to eq('The package upload is invalid: a file must be provided')
          end

          it 'does not create a temporary dir' do
            expect(Dir).to_not receive(:mktmpdir)
            post '/packages', request_body, headers
          end
        end

        context 'when copying the files to the blobstore fails' do
          before do
            allow(blobstore).to receive(:cp_to_blobstore).and_raise(StandardError.new('failed here'))
          end

          it 'return HTTP status 500' do
            post '/packages', request_body, headers
            expect(last_response.status).to eq(500)
          end

          it 'removes the temporary folder' do
            expect(FileUtils).to receive(:rm_f).with(zip_filepath)
            post '/packages', request_body, headers
          end
        end
      end

      describe 'GET /packages' do
        let(:guid) { SecureRandom.uuid }
        let(:blob) { double(:blob) }
        let(:package_file) do
          Tempfile.new('package').tap do |file|
            file.write('content!')
            file.close
          end
        end
        subject(:response) { get "/packages/#{guid}" }

        before do
          allow(blobstore).to receive(:blob).and_return(blob)
          allow(blobstore).to receive(:local?).and_return(true)
          allow_any_instance_of(Packages).to receive(:use_nginx?).and_return(false)
          allow(blob).to receive(:local_path).and_return(package_file.path)
        end

        it 'returns HTTP status 200' do
          expect(response.status).to eq(200)
        end

        it 'returns the blob contents' do
          expect(response.body).to eq(File.read(package_file.path))
        end

        context 'when blobstore is not local' do
          let(:download_url) { 'http://blobstore.com/someblob' }

          before do
            allow(blobstore).to receive(:local?).and_return(false)
            allow(blob).to receive(:download_url).and_return(download_url)
          end

          it 'returns HTTP status 302' do
            expect(response.status).to eq(302)
          end

          it 'returns the blob url in the Location header' do
            expect(response.headers['Location']).to eq(download_url)
          end
        end

        context 'when the bits service is using NGINX' do
          let(:download_url) { 'http://blobstore.com/someblob' }

          before do
            allow_any_instance_of(Packages).to receive(:use_nginx?).and_return(true)
            allow(blob).to receive(:download_url).and_return(download_url)
          end

          it 'returns HTTP status 200' do
            expect(response.status).to eq(200)
          end

          it 'returns the blob url in the X-Accel-Redirect header' do
            expect(response.headers['X-Accel-Redirect']).to eq(download_url)
          end
        end

        context 'when the blob is missing' do
          before do
            allow(blobstore).to receive(:blob).and_return(nil)
          end

          it 'returns HTTP status 404' do
            expect(response.status).to eq(404)
          end
        end

        context 'when fetching the blob object fails' do
          before do
            allow(blobstore).to receive(:blob).and_raise(StandardError)
          end

          it 'returns HTTP status 500' do
            expect(response.status).to eq(500)
          end
        end
      end

      describe 'DELETE /packages/:guid' do
        let(:guid) { SecureRandom.uuid }
        let(:blob) { double(:blob) }

        before do
          allow(blobstore).to receive(:blob).and_return(blob)
          allow(blobstore).to receive(:delete_blob).and_return(blob)
        end

        it 'returns HTTP status 204' do
          delete "/packages/#{guid}", {}
          expect(last_response.status).to eq(204)
        end

        it 'uses the correct key to fetch the blob' do
          expect(blobstore).to receive(:blob).with(guid)
          delete "/packages/#{guid}", {}
        end

        it 'asks for the package to be deleted' do
          expect(blobstore).to receive(:delete_blob).with(blob)
          delete "/packages/#{guid}", {}
        end

        context 'when the package does not exist' do
          before do
            allow(blobstore).to receive(:blob).and_return(nil)
          end

          it 'returns HTTP status 404' do
            delete "/packages/#{guid}", {}
            expect(last_response.status).to eq(404)
          end
        end

        context 'when blobstore lookup fails' do
          before do
            allow(blobstore).to receive(:blob).and_raise
          end

          it 'returns HTTP status 500' do
            delete "/packages/#{guid}", {}
            expect(last_response.status).to eq(500)
          end
        end

        context 'when deleting the blob fails' do
          before do
            allow(blobstore).to receive(:delete_blob).and_raise
          end

          it 'returns HTTP status 500' do
            delete "/packages/#{guid}", {}
            expect(last_response.status).to eq(500)
          end
        end
      end
    end
  end
end
