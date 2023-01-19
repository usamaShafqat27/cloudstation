import CableReady from 'cable_ready'
import consumer from "./consumer"

consumer.subscriptions.create("RoomChannel", {
  connected() {
    // Called when the subscription is ready for use on the server
  },

  disconnected() {
    // Called when the subscription has been terminated by the server
  },

  received(data) {
    // Called when there's incoming data on the websocket for this channel
    if (data.cableReady){
      CableReady.perform(data.operations)
      const last_message = document.querySelector('#room .card:last-child')
      if(last_message)
        last_message.scrollIntoView({behavior: 'smooth'})
      window.operations = data.operations;
      if (data.operations.hasOwnProperty('textContent')){
        const em = document.querySelector(window.operations.textContent[0].selector);
        if (em){
          const room = document.querySelector('#room');
          if (!room || em.parentElement.parentElement.dataset.channelId.replace('channel-', '') != room.dataset.roomId.replace('room-','')){
            const newCount = parseInt(em.dataset.newMsgs) + 1;
            em.dataset.newMsgs = newCount;
            em.parentElement.querySelector('.badge').textContent = newCount;
          }
        }
      }
    }
  }
});
