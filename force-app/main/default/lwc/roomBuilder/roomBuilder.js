import { api, LightningElement } from 'lwc';
import getAthletesAndRooms from '@salesforce/apex/roomBuilder.getAthletesAndRooms';
import updateAthletes from '@salesforce/apex/roomBuilder.updateAthletes';

export default class RoomBuilder extends LightningElement {
    @api
    get webcode() {
        return this._webcode || ''
    }
    set webcode(value) {
        if (!value) return

        this._webcode = value
        getAthletesAndRooms({ webcode: value }).then(resp => {
            console.log('Athletes and Rooms data - ', resp);
            const members = JSON.parse(JSON.stringify(resp.athletes)) || []
            const rooms = JSON.parse(JSON.stringify(resp.rooms)) || []

            const roomObj = {}
            this.members = members.map(member => {
                const roomType = athleteRoomNumberType(member)
                const roomNumPicklistType = athleteRoomType2Number(roomType)
                const roomPreference = roomPicklistType2Number(roomNumPicklistType)
                const key = member.Room__c
                if (key) {
                    if (!roomObj[key]) {
                        roomObj[key] = []
                    }
                    roomObj[key].push(member)
                }
                return { ...member, roomPreference: roomPreference, roomPreferenceName: roomNumPicklistType, inRoom: !!key }
            })
            this.rooms = rooms.map(room => {
                const capacity = roomPicklistType2Number(roomTypeInteger2String(room.Type__c))
                // const type = roomTypeInteger2String()
                return { ...room, assignedMembers: roomObj[room.Id] || [], capacity: capacity, availableSpots: capacity }
            })

            console.log('apex getAthletesAndRooms()')
        })
    }

    renderedCallback() {
        console.log('renderedCallback()')
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
        }).filter(mem => !mem.inRoom);
    }

    // Computed property for rooms with member names
    get roomsWithMemberNames() {
        return this.rooms.map(room => {
            // todo - for each of the rooms we need to update the ring indicator
            const availableSpots = room.capacity - (room.assignedMembers?.length || 0)
            const ringContainer = this.template.querySelector(`.ring-container[data-id="${room.Id}"]`)
            if (ringContainer) {
                this.updateProgressRing(ringContainer, room.assignedMembers?.length || 0, room.capacity)
            }
            return {
                ...room,
                availableSpots
            };
        });
    }

    /* RING START */
    // Initial ring color
    progressColor = '#4a90e2';

    // Function to convert degrees to coordinates on a circle
    degToCoord(deg, radius, center) {
        const rad = (deg - 90) * Math.PI / 180; // -90 to start from the top
        return {
            x: center.x + radius * Math.cos(rad),
            y: center.y + radius * Math.sin(rad)
        };
    }

    // Function to update the progress ring
    updateProgressRing(ringContainer, current, total) {
        const progressArc = ringContainer.querySelector('[data-id="progress-arc"]')
        // Validate inputs
        if (total <= 0) total = 1;
        if (current < 0) current = 0;
        if (current > total) current = total;

        // Calculate progress percentage
        const progressPercentage = current / total;

        // Convert to degrees (full circle is 360 degrees)
        const degrees = progressPercentage * 360;

        // Calculate SVG path
        const center = { x: 50, y: 50 };
        const radius = 40;
        const startPoint = this.degToCoord(0, radius, center);

        console.log('updateProgressRing() ', ringContainer.getAttribute('data-name'), current, total, progressPercentage);

        // If progress is 0, don't show arc
        if (progressPercentage === 0) {
            progressArc.setAttribute('d', '');
            return;
        }

        // If progress is 100%, draw a full circle
        if (progressPercentage === 1) {
            progressArc.setAttribute(
                'd',
                `M ${startPoint.x} ${startPoint.y} ` +
                `A ${radius} ${radius} 0 1 1 ${startPoint.x - 0.001} ${startPoint.y}`
            );
            return;
        }

        // For other percentages, draw an arc
        const endPoint = this.degToCoord(degrees, radius, center);
        const largeArcFlag = degrees > 180 ? 1 : 0;

        progressArc.setAttribute(
            'd',
            `M ${startPoint.x} ${startPoint.y} ` +
            `A ${radius} ${radius} 0 ${largeArcFlag} 1 ${endPoint.x} ${endPoint.y}`
        );

        // Update progress color
        progressArc.setAttribute('stroke', this.progressColor);
    }

    /* RING END */

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
            console.log('handleDrop 2 - ', roomId)
            // Find the member
            const studentIndex = this.members.findIndex(st => st.Id === this.draggedMemberId);
            console.log('handleDrop 3 - ', studentIndex)

            // Reset the dragged member ID
            const draggedMemberId = this.draggedMemberId
            this.draggedMemberId = null
            if (!(studentIndex !== -1)) {
                return
            }
            const member = this.members[studentIndex]

            // Remove member from current room and set inRoom to false
            if (roomId === 'membersArea') {
                this.rooms = this.rooms.map(room => {
                    return {
                        ...room,
                        assignedMembers: room.assignedMembers.filter((mem) => mem.Id !== draggedMemberId)
                    }
                })
                console.log('membersArea - currROom - ')
                member.Room__c = ''
                this.members = [...this.members]
                this.saveAthleteRoomInfo()
                return
            }

            const room = this.rooms.find(rm => rm.Id === roomId);
            if (!room) return

            // Check if the member is already assigned to a room
            const currentRoomId = member.Room__c;
            console.log('inner if 1 - ', currentRoomId)
            // If member is already assigned, remove from current room
            if (currentRoomId) {
                const currentRoom = this.rooms.find(rm => rm.Id === currentRoomId);
                console.log('inner if currentRoom 1 - ', currentRoom)

                if (currentRoom) {
                    currentRoom.assignedMembers = currentRoom.assignedMembers.filter(
                        memberLoop => memberLoop.Id !== draggedMemberId
                    );
                }
            }
            console.log('inner if 2 - ')

            // Check if member preference matches room capacity
            if (member.roomPreference !== room.capacity) {
                // eslint-disable-next-line no-alert
                alert(`User ${member.Name} can only go in rooms of size ${member.roomPreference}`)
                return
            }

            // Check if the room has capacity
            if (room.assignedMembers.length < room.capacity) {
                // Assign member to new room
                member.Room__c = roomId;
                console.log('inner if 3 - ', member, ' - ', member.Room__c)

                // Add member to room's assigned members if not already there
                if (!room.assignedMembers.find((mem) => mem.Id === draggedMemberId)) {
                    room.assignedMembers.push(member);
                }

                // Force refresh of UI
                this.members = [...this.members]
                this.rooms = [...this.rooms];
                this.saveAthleteRoomInfo()
            } else {
                // Room is at capacity
                // eslint-disable-next-line no-alert
                alert(`Room ${room.Name} is already at capacity!`);
            }
        } catch (err) {
            console.log("err - ", err)
        }
    }


    // Call apex
    saveAthleteRoomInfo() {
        updateAthletes({ athletes: this.members }).then(() => {
        })
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