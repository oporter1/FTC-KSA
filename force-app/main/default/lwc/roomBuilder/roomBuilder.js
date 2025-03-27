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
            const members = JSON.parse(JSON.stringify(resp.athletes)) || []
            const rooms = JSON.parse(JSON.stringify(resp.rooms)) || []

            this.members = members.map(member => {
                const roomType = athleteRoomNumberType(member)
                const roomNumPicklistType = athleteRoomType2Number(roomType)
                const roomPreference = roomPicklistType2Number(roomNumPicklistType)
                return { ...member, roomPreference: roomPreference, roomPreferenceName: roomNumPicklistType }
            })
            this.rooms = rooms.map(room => {
                const capacity = roomPicklistType2Number(roomTypeInteger2String(room.Type__c))
                // const type = roomTypeInteger2String()
                return { ...room, assignedMembers: [], capacity: capacity }
            })
        })
    }

    connectedCallback() {
        console.log('lwc room builder connected - ', this.webcode);
    }

    renderedCallback() {
        console.log('lwc room builder rendered - ', this.webcode);
    }

    members = []
    rooms = []

    // Current member being dragged
    draggedMemberId = null;

    // Computed property for members with room names
    get membersWithRoomInfo() {
        return this.members.map(member => {
            const roomId = member.Room__c;
            const room = roomId ? this.rooms.find(rm => rm.Id === roomId) : null;
            return {
                ...member,
                roomName: room ? room.Name : null
            };
        });
    }

    // Computed property for rooms with member names
    get roomsWithMemberNames() {
        return this.rooms.map(room => {
            const assignedMemberNames = room.assignedMembers?.map(studentId => {
                const member = this.members.find(st => st.Id === studentId);
                return {
                    Id: studentId,
                    Name: member ? member.Name : 'Unknown Member'
                };
            }) || [];

            return {
                ...room,
                assignedMemberNames
            };
        });
    }

    handleDragStart(event) {
        // Store the member ID being dragged
        event.currentTarget.classList.add('dragging');
        this.draggedMemberId = event.currentTarget.dataset.id;

        // Set transfer data (optional but recommended for cross-browser compatibility)
        event.dataTransfer.setData('text/plain', this.draggedMemberId);

        // Set the drag effect
        event.dataTransfer.effectAllowed = 'move';
    }

    // Add this method to handle drag end
    handleDragEnd(event) {
        // Remove dragging class
        event.currentTarget.classList.remove('dragging');

        // Reset any drag-over elements
        const roomElements = this.template.querySelectorAll('.room-item');
        roomElements.forEach(elem => {
            elem.classList.remove('drag-over');
        });
    }

    handleDragOver(event) {
        // Prevent default to allow drop
        event.preventDefault();
        event.dataTransfer.dropEffect = 'move';
        event.currentTarget.classList.add('drag-over');
    }
    handleDragLeave(event) {
        // Remove drag-over class when dragging leaves the element
        event.currentTarget.classList.remove('drag-over');
    }

    handleDrop(event) {
        try {
            // Prevent default action
            event.preventDefault();
            event.currentTarget.classList.remove('drag-over');
            // Get the room ID where the member was dropped
            const roomId = event.currentTarget.dataset.id;
            // Find the room
            const room = this.rooms.find(rm => rm.Id === roomId);
            console.log('handleDrop 2 - ', room)
            // Find the member
            const studentIndex = this.members.findIndex(st => st.Id === this.draggedMemberId);
            console.log('handleDrop 3 - ', studentIndex)

            if (room && studentIndex !== -1) {
                // Check if the member is already assigned to a room
                const currentRoomId = this.members[studentIndex].Room__c;
                console.log('inner if 1 - ', currentRoomId)
                // If member is already assigned, remove from current room
                if (currentRoomId) {
                    const currentRoom = this.rooms.find(rm => rm.Id === currentRoomId);
                    console.log('inner if currentRoom 1 - ', currentRoom)

                    if (currentRoom) {
                        currentRoom.assignedMembers = currentRoom.assignedMembers.filter(
                            Id => Id !== this.draggedMemberId
                        );
                    }
                }
                console.log('inner if 2 - ')

                // Check if the room has capacity
                if (room.assignedMembers.length < room.capacity) {
                    // Assign member to new room
                    this.members[studentIndex].Room__c = roomId;
                    console.log('inner if 3 - ', this.members[studentIndex], ' - ', this.members[studentIndex].Room__c)

                    // Add member to room's assigned members if not already there
                    if (!room.assignedMembers.includes(this.draggedMemberId)) {
                        room.assignedMembers.push(this.draggedMemberId);
                    }

                    // Force refresh of UI
                    this.members = [...this.members];
                    this.rooms = [...this.rooms];
                } else {
                    // Room is at capacity
                    // eslint-disable-next-line no-alert
                    alert(`Room ${room.Name} is already at capacity!`);
                }
            }

            // Reset the dragged member ID
            this.draggedMemberId = null;
        } catch (err) {
            console.log("err - ", err)
        }
    }
}

function athleteRoomNumberType(athlete) {
    const keys = ['Single_Room__c', 'Double_Room__c', 'Triple_Room__c', 'Quad_Rooms__c']
    for (const key of keys) {
        if (!!athlete[key]) {
            return athlete[key]
        }
    }
    return 0
}

function athleteRoomType2Number(roomTypeNum) {
    if (roomTypeNum === 0.25) {
        return 'Quad';
    } else if (roomTypeNum >= 0.3 && roomTypeNum <= 0.34) {
        return 'Triple';
    } else if (roomTypeNum === 0.5) {
        return 'Double';
    } else if (roomTypeNum === 1) {
        return 'Single';
    }
    return 'None';
}

function roomPicklistType2Number(roomType) {
    if (roomType === 'Quad') {
        return 4;
    } else if (roomType === 'Triple') {
        return 3;
    } else if (roomType === 'Double') {
        return 2;
    } else if (roomType === 'Single') {
        return 1;
    }
    return 0;
}

function roomTypeInteger2String(roomTypeNumberAsString) {
    if (roomTypeNumberAsString === '4') {
        return 'Quad';
    } else if (roomTypeNumberAsString === '3') {
        return 'Triple';
    } else if (roomTypeNumberAsString === '2') {
        return 'Double';
    } else if (roomTypeNumberAsString === '1') {
        return 'Single';
    }
    return 0;
}