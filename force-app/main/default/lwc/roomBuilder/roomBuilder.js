import { api, LightningElement } from 'lwc';
import getAthletesAndRooms from '@salesforce/apex/roomBuilder.getAthletesAndRooms';

export default class RoomBuilder extends LightningElement {
    @api
    get webcode() {
        return this._webcode || ''
    }
    set webcode(value) {
        if (!value) return

        this._webcode = value
        console.log('webCode - ', value)
        getAthletesAndRooms({ webcode: value }).then(resp => {
            console.log('Athletes and Rooms data - ', resp);
        })
    }
    athletesAndRooms;

    connectedCallback() {
        console.log('lwc room builder connected - ', this.webcode);
    }

    renderedCallback() {
        console.log('lwc room builder rendered - ', this.webcode);
    }
}