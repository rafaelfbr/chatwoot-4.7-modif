# https://docs.360dialog.com/whatsapp-api/whatsapp-api/media
# https://developers.facebook.com/docs/whatsapp/api/media/

class Whatsapp::IncomingMessageService < Whatsapp::IncomingMessageBaseService

  # O método abaixo sobrescreve o método original do arquivo "pai"
  # (incoming_message_base_service.rb)
  #
  # Nós o copiamos e adicionamos a lógica da Issue #12560
  # para capturar os dados de 'referral' e 'url_preview'.

  private

  def create_regular_message(message)
    # --- INÍCIO DA MODIFICAÇÃO DA ISSUE #12560 ---

    # 1. Extrair os dados de 'referral' e 'url_preview' do objeto 'message'
    url_preview = message[:url_preview]
    referral = message[:referral]

    # 2. Preparar o hash de 'content_attributes' (só o criamos se os dados existirem)
    content_attrs = {}
    if url_preview.present? || referral.present?
      content_attrs[:whatsapp] = {
        url_preview: url_preview,
        referral: referral
      }
    end
    # --- FIM DA MODIFICAÇÃO DA ISSUE #12560 ---

    # 3. Código copiado do método 'create_message(message)' do arquivo "pai"
    #    Tivemos que copiá-lo para poder adicionar a nova linha 'content_attributes'
    @message = @conversation.messages.build(
      content: message_content(message),
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: message[:id].to_s,
      in_reply_to_external_id: @in_reply_to_external_id,

      # 4. ADIÇÃO DA NOVA LINHA:
      #    Aqui é onde salvamos os dados do anúncio no banco de dados.
      content_attributes: content_attrs
    )

    # 5. Restante do código original de 'create_regular_message' do arquivo "pai"
    attach_files
    attach_location if message_type == 'location'
    @message.save!
  end
end