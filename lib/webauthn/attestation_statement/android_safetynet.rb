# frozen_string_literal: true

require "android_safetynet/attestation_response"
require "openssl"
require "webauthn/attestation_statement/base"

module WebAuthn
  module AttestationStatement
    # Implements https://www.w3.org/TR/webauthn-1/#sctn-android-safetynet-attestation
    class AndroidSafetynet < Base
      def valid?(authenticator_data, client_data_hash)
        valid_response?(authenticator_data, client_data_hash) &&
          valid_version? &&
          cts_profile_match? &&
          [WebAuthn::AttestationStatement::ATTESTATION_TYPE_BASIC, attestation_trust_path]
      end

      def attestation_certificate
        attestation_response.leaf_certificate
      end

      private

      def valid_response?(authenticator_data, client_data_hash)
        nonce = Digest::SHA256.base64digest(authenticator_data.data + client_data_hash)

        begin
          attestation_response.verify(nonce)
        rescue ::AndroidSafetynet::AttestationResponse::VerificationError
          false
        end
      end

      # TODO: improve once the spec has clarifications https://github.com/w3c/webauthn/issues/968
      def valid_version?
        !statement["ver"].empty?
      end

      def cts_profile_match?
        attestation_response.cts_profile_match?
      end

      def attestation_trust_path
        # FIXME: Change this to be the chain.
        #
        # The WebAuthn Level 1 spec said this needs to be just the attestation certificate.
        # However, that was an error and it fixed on the Level 2 draft version.
        #
        # See https://github.com/w3c/webauthn/pull/1142
        attestation_certificate
      end

      def attestation_response
        @attestation_response ||= ::AndroidSafetynet::AttestationResponse.new(statement["response"])
      end
    end
  end
end
