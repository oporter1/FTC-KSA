/* ─────────────────────────────────────────────────────────────────────────────────────────────────
* TITLE:          roomBuilder  lwc
* DESCRIPTION:    handles the UI + frontend logic for dragging and dropping athletes into rooms
* @created        03/24/2025
* @updated
* @by             FTC       hey@freethinkersconsulting.com
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @notes: 
*/

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
            const members = JSON.parse(JSON.stringify(resp.athletes)) || []
            const rooms = JSON.parse(JSON.stringify(resp.rooms)) || []
            console.log('resp - ', resp)
            const roomObj = {}
            this.members = members.map(member => {
                const roomType = athleteRoomNumberType(member)
                const roomNumPicklistType = athleteRoomType2Number(roomType)
                const roomPreference = roomPicklistType2Number(roomNumPicklistType)
                const key = member.Room__c
                const newObj = { ...member, roomPreference: roomPreference, roomPreferenceName: roomNumPicklistType, inRoom: !!key, schoolName: member?.School_Contact__r?.Name || 'No Contact Name' }
                if (key) {
                    if (!roomObj[key]) {
                        roomObj[key] = []
                    }
                    roomObj[key].push(newObj)
                }
                return newObj
            })
            this.rooms = rooms.map(room => {
                const capacity = roomPicklistType2Number(roomTypeInteger2String(room.Type__c))
                // const type = roomTypeInteger2String()
                const numMembers = roomObj[room.Id]?.length || 0
                const availableSpots = capacity - numMembers
                const spotsLeftText = numMembers === 0 ? 'No occupants' : numMembers === capacity ? 'Full Room' : `${availableSpots} Spot${availableSpots === 1 ? '' : 's'} left`
                return { ...room, assignedMembers: roomObj[room.Id] || [], capacity: capacity, availableSpots, spotsLeftText, isFull: numMembers === capacity }
            })
            this.updateRings = true
        })
    }

    errorMsg = ''
    toastContainer
    updateRings = true
    renderedCallback() {
        // re-generate the ring 
        if (this.updateRings) {
            const triggerGetter = this.roomsWithMemberNames     // variable used to trigger the getter on the right side of =
            this.updateRings = false
        }

        if (this.toastContainer) return
        this.toastContainer = this.template.querySelector('.toastContainer');
    }

    members = []
    rooms = []

    // Current member being dragged
    draggedMemberId = null;

    searchFilter = ''
    sortMembers = true
    sortRooms = true
    // Computed property for members with room names
    get membersWithRoomInfo() {
        return this.members.map(member => {
            const roomId = member.Room__c;
            // const room = roomId ? this.rooms.find(rm => rm.Id === roomId) : null;
            return {
                ...member,
                inRoom: !!roomId
            };
        }).filter(mem => !mem.inRoom)
            .filter((mem) => mem.schoolName.toLowerCase().includes(this.searchFilter.toLowerCase()))
            .sort((a, b) => {
                if (this.sortMembers) {
                    return a.schoolName.localeCompare(b.schoolName)
                }
                return b.schoolName.localeCompare(a.schoolName)
            });
    }

    sortStudents(e) {
        this.sortMembers = !this.sortMembers
        if (this.sortMembers) {
            e.currentTarget.classList.remove('rotate-180')
        } else {
            e.currentTarget.classList.add('rotate-180')
        }
        console.log('sortStudents curr- ', this.sortMembers, e.target.classList)
    }

    sortRoomsFn(e) {
        this.sortRooms = !this.sortRooms
        if (this.sortRooms) {
            e.currentTarget.classList.remove('rotate-180')
        } else {
            e.currentTarget.classList.add('rotate-180')
        }
        console.log('sortRooms curr- ', this.sortRooms, e.target.classList)
    }

    // Filters out the athletes list based on the search input
    handleSearchInput(event) {
        this.searchFilter = event.target.value;
    }

    // Computed property for rooms with member names
    get roomsWithMemberNames() {
        return this.rooms.map(room => {
            // todo - for each of the rooms we need to update the ring indicator
            const numMembers = room.assignedMembers?.length || 0
            const availableSpots = room.capacity - numMembers
            const spotsLeftText = numMembers === 0 ? 'No occupants' : numMembers === room.capacity ? 'Full Room' : `${availableSpots} Spot${availableSpots === 1 ? '' : 's'} left`
            const ringContainer = this.template.querySelector(`.ring-container[data-id="${room.Id}"]`)
            if (ringContainer) {
                if (numMembers === room.capacity) {
                    ringContainer.classList.add('green-background');
                } else {
                    ringContainer.classList.remove('green-background');
                }
                try {
                    this.updateProgressRing(ringContainer, numMembers, room.capacity)
                } catch (err) {
                    console.log('ringUpdate error - ', room.Name)
                }
                this.updateRings = true
            }
            return {
                ...room,
                availableSpots,
                spotsLeftText,
                isFull: numMembers === room.capacity
            };
        }).sort((a, b) => {
            if (this.sortRooms) {
                return a?.Room_Number__c - b?.Room_Number__c
            }
            return b?.Room_Number__c - a?.Room_Number__c
        })
    }

    /* RING START */
    // Initial ring color
    progressColor = '#EB5757';

    // Function to convert degrees to coordinates on a circle
    degToCoord(deg, radius, center, startDeg = -90) {
        const rad = (deg + startDeg) * Math.PI / 180; // -90 to start from the top
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
        if (current === total) return
        // Calculate progress percentage
        const progressPercentage = current / total;

        // Convert to degrees (full circle is 360 degrees)
        const degrees = progressPercentage * 360;

        // Calculate SVG path
        const center = { x: 50, y: 50 };
        const radius = 40;
        const startPoint = progressPercentage === 1 ? this.degToCoord(0, radius, center, -90) : this.degToCoord(0, radius, center, 0);

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
        const endPoint = progressPercentage === 1 ? this.degToCoord(degrees, radius, center, -90) : this.degToCoord(degrees, radius, center, 0);
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

    /* DRAG DROP START */
    handleDragStart(event) {
        // Store the member ID being dragged
        event.currentTarget.classList.add('dragging');
        this.draggedMemberId = event.currentTarget.dataset.id;

        // Set transfer data (optional but recommended for cross-browser compatibility)
        event.dataTransfer.setData('text/plain', this.draggedMemberId);

        // Set the drag effect
        event.dataTransfer.effectAllowed = 'move';
    }

    draggedElement
    isDragging = false
    touchOffsetX = 0
    touchOffsetY = 0
    startX = 0
    startY = 0
    validElementList = []
    memberArea
    handleTouchStart(event) {
        const touch = event.touches[0];

        // event.currentTarget.classList.add('dragging');
        this.draggedMemberId = event.currentTarget.dataset.id;

        this.draggedElement = event.currentTarget
        const rect = this.draggedElement.getBoundingClientRect();
        this.startX = rect.clientX
        this.startY = rect.clientY

        this.touchOffsetX = touch.clientX - rect.left;
        this.touchOffsetY = touch.clientY - rect.top;

        // eslint-disable-next-line @lwc/lwc/no-async-operation
        setTimeout(() => {
            if (this.draggedElement) {
                this.isDragging = true;

                // Create visual feedback (clone or styling)
                this.draggedElement.classList.add('dragging');
                this.draggedElement.classList.add('member-item-hover')

            }
        }, 100); // Adjust timeout as needed

        // Update list of x,ys for all drag over areas
        this.memberArea = this.template.querySelector('.member-list-ul')
        const member = this.members.find(mem => mem.Id === this.draggedMemberId)
        const elements = Array.from(this.template.querySelectorAll('.room-item') || [])
        this.validElementList = []
        elements.forEach((elem) => {
            if (elem.getAttribute('data-room-size') === `${member.roomPreference}`) {
                elem.classList.add('drag-over')
            }
            this.validElementList.push(elem)
        })
        this.validElementList.push(this.memberArea)
        this.memberArea.classList.add('drag-over')
        event.preventDefault();
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

    handleTouchEnd(event) {
        event.currentTarget.classList.remove('dragging');
        this.draggedElement.classList.remove('member-item-hover');
        this.isDragging = false
        // Reset any drag-over elements
        const roomElements = this.template.querySelectorAll('.room-item');
        roomElements.forEach(elem => {
            elem.classList.remove('drag-over');
        });

        Array.from(this.template.querySelectorAll('.member-item') || []).forEach((elem) => {
            elem?.classList?.remove('dragging')
        })

        this.memberArea.classList.remove('drag-over')

        // Check for overlapping elements and handle drop
        this.validElementList.forEach((elem) => {
            // Get bounding rectangles to check for overlap
            const elemRect = elem.getBoundingClientRect();
            const draggedRect = this.draggedElement.getBoundingClientRect();

            // Check if elements are overlapping
            const isOverlapping = !(
                elemRect.right < draggedRect.left ||
                elemRect.left > draggedRect.right ||
                elemRect.bottom < draggedRect.top ||
                elemRect.top > draggedRect.bottom
            );

            // If overlapping, handle the drop into the room
            if (isOverlapping) {
                // Create a synthetic event with the room's dataset
                const syntheticEvent = {
                    preventDefault: () => { },
                    currentTarget: {
                        dataset: { id: elem.dataset.id },
                        classList: { remove: () => { } }
                    }
                };

                // Call the drop handler with our synthetic event
                this.handleDrop(syntheticEvent);
            }
        });

        // Set back to original location
        this.draggedElement.style.position = 'unset';
        this.draggedElement = null
    }

    handleTouchMove(event) {
        if (!this.isDragging || !this.draggedElement) return;
        const touch = event.touches[0]
        // Move element
        this.draggedElement.style.position = 'fixed';

        this.draggedElement.style.left = `${touch.clientX - this.touchOffsetX}px`;
        this.draggedElement.style.top = `${touch.clientY - this.touchOffsetY}px`;
    }

    handleDragOver(event) {
        // Prevent default to allow drop
        event.dataTransfer.dropEffect = 'move';
        event.currentTarget.classList.add('drag-over');
        event.preventDefault();
    }
    handleDragLeave(event) {
        // Remove drag-over class when dragging leaves the element
        event.currentTarget.classList.remove('drag-over');
    }

    handleDrop(event) {
        try {
            // Prevent default action
            event.currentTarget.classList.remove('drag-over');
            // Get the room ID where the member was dropped
            const roomId = event.currentTarget.dataset.id;

            // Find the room
            // Find the member
            const studentIndex = this.members.findIndex(st => st.Id === this.draggedMemberId);

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
                member.Room__c = ''
                this.members = [...this.members]
                this.saveAthleteRoomInfo()
                return
            }

            const room = this.rooms.find(rm => rm.Id === roomId);
            if (!room) return

            // Check if member preference matches room capacity
            if (member.roomPreference !== room.capacity) {
                // Room is at capacity
                this.errorMsg = `User ${member.schoolName} can only go in rooms of size ${member.roomPreference}`
                this.errorAlert()
                return
            }

            // Check if the room has capacity
            const currentRoomId = member.Room__c;
            if (room.assignedMembers.length < room.capacity) {

                // Assign member to new room
                member.Room__c = roomId;

                // Check if the member is already assigned to a room and remove them from it
                if (currentRoomId) {
                    const currentRoom = this.rooms.find(rm => rm.Id === currentRoomId);

                    console.log('currentRoom if - ', currentRoom, room, currentRoom === room)
                    // If member already in same room do nothing
                    if (currentRoom === room) {
                        return
                    }

                    if (currentRoom) {
                        currentRoom.assignedMembers = currentRoom.assignedMembers.filter(
                            memberLoop => memberLoop.Id !== draggedMemberId
                        );
                    }
                }

                // Add member to room's assigned members if not already there
                if (!room.assignedMembers.find((mem) => mem.Id === draggedMemberId)) {
                    room.assignedMembers.push(member);
                }

                // Force refresh of UI
                this.members = [...this.members]
                this.rooms = [...this.rooms];
                this.saveAthleteRoomInfo()
            } else {
                // Check if the member is already assigned to a room and remove them from it
                if (currentRoomId) {
                    const currentRoom = this.rooms.find(rm => rm.Id === currentRoomId);

                    console.log('currentRoom else - ', currentRoom, room, currentRoom === room)
                    // If member already in same room do nothing
                    if (currentRoom === room) {
                        return
                    }
                }

                // Room is at capacity
                this.errorMsg = `Room ${room.Room_Number__c} is already at capacity!`
                this.errorAlert()
            }
        } catch (err) {
            console.log("err - ", err)
        }
        event.preventDefault();
    }
    /* DRAG DROP END */
    firstToast = true
    errorAlert() {
        const toastEl = this.toastContainer
        if (toastEl) {

            if (this.firstToast) {
                toastEl.style.display = 'block';
                toastEl.style.zIndex = '9999';
                toastEl.style.position = 'fixed';
                toastEl.style.top = '10%';
                toastEl.style.left = '50%';
                toastEl.style.transform = 'translateX(-50%)';
                document.body.appendChild(toastEl)  // breaks out of the z-stack to appear over the nav bar
                this.firstToast = false
            } else {
                toastEl.style.display = 'block'
            }
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                toastEl.style.display = 'none';
            }, 5000);
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