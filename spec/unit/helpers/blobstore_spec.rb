require 'spec_helper'

module BitsService
  module Helpers
    describe Blobstore do
      class Test
        include Blobstore
      end

      subject { Test.new }

      before(:each) do
        allow(subject).to receive(:config).and_return(config)
      end

      describe 'blobstore' do
        let(:config) do
          {
            buildpacks: {
              fog_connection: 'fog_connection',
              directory_key: 'directory_key'
            },
            buildpack_cache: {
              fog_connection: 'fog_connection',
              directory_key: 'directory_key_bc'
            },
            droplets: {
              fog_connection: 'fog_connection',
              directory_key: 'directory_key'
            },
            packages: {
              fog_connection: 'fog_connection',
              directory_key: 'directory_key'
            }
          }
        end

        context 'buildpacks' do
          it 'returns a blobstore client' do
            expect(subject.buildpack_blobstore).to be_a(BitsService::Blobstore::Client)
          end

          it 'creates a blobstore client with the correct config' do
            expect(BitsService::Blobstore::Client).to receive(:new).with('fog_connection', 'directory_key')
            subject.buildpack_blobstore
          end

          context 'when :directory_key is not present in config' do
            let(:config) do
              {
                buildpacks: {
                  fog_connection: 'fog_connection'
                }
              }
            end

            it 'creates a blobstore client with the correct default directory key' do
              expect(BitsService::Blobstore::Client).to receive(:new).with('fog_connection', 'buildpacks')
              subject.buildpack_blobstore
            end
          end

          context 'when config is missing the :buildpacks key' do
            let(:config) { Hash.new }

            it 'throws an exception' do
              expect { subject.buildpack_blobstore }.to raise_error(KeyError, /:buildpacks/)
            end
          end

          context 'when config is missing the :fog_connection key' do
            let(:config) { { buildpacks: {} } }

            it 'throws an exception' do
              expect { subject.buildpack_blobstore }.to raise_error(KeyError, /:fog_connection/)
            end
          end
        end

        context 'buildpack_cache' do
          it 'returns a blobstore client' do
            expect(subject.buildpack_cache_blobstore).to be_a(BitsService::Blobstore::Client)
          end

          it 'creates a blobstore client with the correct config' do
            expect(BitsService::Blobstore::Client).to receive(:new).with('fog_connection', 'directory_key_bc')
            subject.buildpack_cache_blobstore
          end

          context 'when :directory_key is not present in config' do
            let(:config) do
              {
                buildpack_cache: {
                  fog_connection: 'fog_connection'
                }
              }
            end

            it 'creates a blobstore client with the correct default directory key' do
              expect(BitsService::Blobstore::Client).to receive(:new).with('fog_connection', 'buildpack_cache')
              subject.buildpack_cache_blobstore
            end
          end

          context 'when config is missing the :buildpack_cache key' do
            let(:config) { Hash.new }

            it 'throws an exception' do
              expect { subject.buildpack_cache_blobstore }.to raise_error(KeyError, /:buildpack_cache/)
            end
          end

          context 'when config is missing the :fog_connection key' do
            let(:config) { { buildpack_cache: {} } }

            it 'throws an exception' do
              expect { subject.buildpack_cache_blobstore }.to raise_error(KeyError, /:fog_connection/)
            end
          end
        end

        context 'droplets' do
          it 'returns a blobstore client' do
            expect(subject.droplet_blobstore).to be_a(BitsService::Blobstore::Client)
          end

          it 'creates a blobstore client with the correct config' do
            expect(BitsService::Blobstore::Client).to receive(:new).with('fog_connection', 'directory_key')
            subject.droplet_blobstore
          end

          context 'when :directory_key is not present in config' do
            let(:config) do
              {
                droplets: {
                  fog_connection: 'fog_connection'
                }
              }
            end

            it 'creates a blobstore client with the correct default directory key' do
              expect(BitsService::Blobstore::Client).to receive(:new).with('fog_connection', 'droplets')
              subject.droplet_blobstore
            end
          end

          context 'when config is missing the :droplets key' do
            let(:config) { Hash.new }

            it 'throws an exception' do
              expect { subject.droplet_blobstore }.to raise_error(KeyError, /:droplets/)
            end
          end

          context 'when config is missing the :fog_connection key' do
            let(:config) { { droplets: {} } }

            it 'throws an exception' do
              expect { subject.droplet_blobstore }.to raise_error(KeyError, /:fog_connection/)
            end
          end
        end

        context 'packages' do
          it 'returns a blobstore client' do
            expect(subject.packages_blobstore).to be_a(BitsService::Blobstore::Client)
          end

          it 'creates a blobstore client with the correct config' do
            expect(BitsService::Blobstore::Client).to receive(:new).with('fog_connection', 'directory_key')
            subject.packages_blobstore
          end

          context 'when :directory_key is not present in config' do
            let(:config) do
              {
                packages: {
                  fog_connection: 'fog_connection'
                }
              }
            end

            it 'creates a blobstore client with the correct default directory key' do
              expect(BitsService::Blobstore::Client).to receive(:new).with('fog_connection', 'packages')
              subject.packages_blobstore
            end
          end

          context 'when config is missing the :droplets key' do
            let(:config) { Hash.new }

            it 'throws an exception' do
              expect { subject.packages_blobstore }.to raise_error(KeyError, /:packages/)
            end
          end

          context 'when config is missing the :fog_connection key' do
            let(:config) { { packages: {} } }

            it 'throws an exception' do
              expect { subject.packages_blobstore }.to raise_error(KeyError, /:fog_connection/)
            end
          end
        end
      end

      describe 'app_stash_blobstore' do
        let(:config) do
          {
            app_stash: {
              fog_connection: 'fog_connection',
              directory_key: 'directory_key'
            }
          }
        end

        it 'returns a blobstore client' do
          expect(subject.app_stash_blobstore).to be_a(BitsService::Blobstore::Client)
        end

        it 'creates a blobstore client with the correct config' do
          expect(BitsService::Blobstore::Client).to receive(:new).with('fog_connection', 'directory_key')
          subject.app_stash_blobstore
        end

        context 'when :directory_key is not present in config' do
          let(:config) do
            {
              app_stash: {
                fog_connection: 'fog_connection'
              }
            }
          end

          it 'creates a blobstore client with the correct default directory key' do
            expect(BitsService::Blobstore::Client).to receive(:new).with('fog_connection', 'app_stash')
            subject.app_stash_blobstore
          end
        end

        context 'when config is missing the :buildpacks key' do
          let(:config) { Hash.new }

          it 'throws an exception' do
            expect { subject.app_stash_blobstore }.to raise_error(KeyError, /:app_stash/)
          end
        end

        context 'when config is missing the :fog_connection key' do
          let(:config) { { app_stash: {} } }

          it 'throws an exception' do
            expect { subject.app_stash_blobstore }.to raise_error(KeyError, /:fog_connection/)
          end
        end
      end
    end
  end
end
