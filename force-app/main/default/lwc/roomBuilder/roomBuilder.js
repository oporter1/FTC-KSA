import { api, LightningElement, track } from 'lwc';
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

    @track students = [
        { id: 's1', name: 'John Doe', roomId: null },
        { id: 's2', name: 'Jane Smith', roomId: null },
        { id: 's3', name: 'Mike Johnson', roomId: null },
        { id: 's4', name: 'Sara Williams', roomId: null },
        { id: 's5', name: 'Robert Brown', roomId: null },
        { id: 's6', name: 'Emily Davis', roomId: null }
    ];

    @track rooms = [
        { id: 'r1', name: 'Room 101', capacity: 3, assignedStudents: [] },
        { id: 'r2', name: 'Room 102', capacity: 2, assignedStudents: [] },
        { id: 'r3', name: 'Room 103', capacity: 4, assignedStudents: [] }
    ];

    // Current student being dragged
    draggedStudentId = null;

    // Computed property for students with room names
    get studentsWithRoomInfo() {
        return this.students.map(student => {
            const roomId = student.roomId;
            const room = roomId ? this.rooms.find(rm => rm.id === roomId) : null;
            return {
                ...student,
                roomName: room ? room.name : null
            };
        });
    }

    // Computed property for rooms with student names
    get roomsWithStudentNames() {
        return this.rooms.map(room => {
            const assignedStudentNames = room.assignedStudents.map(studentId => {
                const student = this.students.find(st => st.id === studentId);
                return {
                    id: studentId,
                    name: student ? student.name : 'Unknown Student'
                };
            });

            return {
                ...room,
                assignedStudentNames
            };
        });
    }

    handleDragStart(event) {
        // Store the student ID being dragged
        event.currentTarget.classList.add('dragging');

        this.draggedStudentId = event.currentTarget.dataset.id;

        // Set transfer data (optional but recommended for cross-browser compatibility)
        event.dataTransfer.setData('text/plain', this.draggedStudentId);

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
        // Prevent default action
        event.preventDefault();
        event.currentTarget.classList.remove('drag-over');

        // Get the room ID where the student was dropped
        const roomId = event.currentTarget.dataset.id;

        // Find the room
        const room = this.rooms.find(rm => rm.id === roomId);

        // Find the student
        const studentIndex = this.students.findIndex(st => st.id === this.draggedStudentId);

        if (room && studentIndex !== -1) {
            // Check if the student is already assigned to a room
            const currentRoomId = this.students[studentIndex].roomId;

            // If student is already assigned, remove from current room
            if (currentRoomId) {
                const currentRoom = this.rooms.find(rm => rm.id === currentRoomId);
                if (currentRoom) {
                    currentRoom.assignedStudents = currentRoom.assignedStudents.filter(
                        id => id !== this.draggedStudentId
                    );
                }
            }

            // Check if the room has capacity
            if (room.assignedStudents.length < room.capacity) {
                // Assign student to new room
                this.students[studentIndex].roomId = roomId;

                // Add student to room's assigned students if not already there
                if (!room.assignedStudents.includes(this.draggedStudentId)) {
                    room.assignedStudents.push(this.draggedStudentId);
                }

                // Force refresh of UI
                this.students = [...this.students];
                this.rooms = [...this.rooms];
            } else {
                // Room is at capacity
                // eslint-disable-next-line no-alert
                alert(`Room ${room.name} is already at capacity!`);
            }
        }

        // Reset the dragged student ID
        this.draggedStudentId = null;
    }
}