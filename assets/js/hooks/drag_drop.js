export const DragDrop = {
  mounted() {
    this.initializeDragDrop();
  },

  updated() {
    this.initializeDragDrop();
  },

  initializeDragDrop() {
    // Make tasks draggable
    this.el.querySelectorAll('[data-draggable="task"]').forEach(task => {
      task.draggable = true;
      task.addEventListener('dragstart', this.handleDragStart.bind(this));
      task.addEventListener('dragend', this.handleDragEnd.bind(this));
    });

    // Make columns droppable
    this.el.querySelectorAll('[data-droppable="column"]').forEach(column => {
      column.addEventListener('dragover', this.handleDragOver.bind(this));
      column.addEventListener('drop', this.handleDrop.bind(this));
      column.addEventListener('dragenter', this.handleDragEnter.bind(this));
      column.addEventListener('dragleave', this.handleDragLeave.bind(this));
    });
  },

  handleDragStart(e) {
    const taskElement = e.target.closest('[data-task-id]');
    const taskId = taskElement.dataset.taskId;
    const currentColumnId = taskElement.closest('[data-column-id]').dataset.columnId;
    
    // Store drag data
    e.dataTransfer.setData('text/plain', JSON.stringify({
      taskId: taskId,
      sourceColumnId: currentColumnId
    }));
    
    // Add visual feedback
    taskElement.classList.add('opacity-50', 'transform', 'rotate-2');
    taskElement.style.transform = 'rotate(2deg)';
    
    // Add dragging class to body for global styles
    document.body.classList.add('dragging');
  },

  handleDragEnd(e) {
    const taskElement = e.target.closest('[data-task-id]');
    
    // Remove visual feedback
    taskElement.classList.remove('opacity-50', 'transform', 'rotate-2');
    taskElement.style.transform = '';
    
    // Remove global dragging state
    document.body.classList.remove('dragging');
    
    // Remove drop zone highlights
    document.querySelectorAll('.drag-over').forEach(el => {
      el.classList.remove('drag-over');
    });
  },

  handleDragOver(e) {
    e.preventDefault(); // Allow drop
    e.dataTransfer.dropEffect = 'move';
  },

  handleDragEnter(e) {
    e.preventDefault();
    const column = e.target.closest('[data-droppable="column"]');
    if (column) {
      column.classList.add('drag-over');
    }
  },

  handleDragLeave(e) {
    const column = e.target.closest('[data-droppable="column"]');
    if (column && !column.contains(e.relatedTarget)) {
      column.classList.remove('drag-over');
    }
  },

  handleDrop(e) {
    e.preventDefault();
    
    const column = e.target.closest('[data-droppable="column"]');
    const targetColumnId = column.dataset.columnId;
    
    // Remove visual feedback
    column.classList.remove('drag-over');
    
    try {
      const dragData = JSON.parse(e.dataTransfer.getData('text/plain'));
      const { taskId, sourceColumnId } = dragData;
      
      // Only move if dropping in different column
      if (sourceColumnId !== targetColumnId) {
        // Calculate drop position (simple: add to end)
        const tasksInColumn = column.querySelectorAll('[data-task-id]').length;
        const position = tasksInColumn + 1;
        
        // Trigger LiveView event
        this.pushEvent('move_task_drag', {
          task_id: taskId,
          column_id: targetColumnId,
          position: position
        });
      }
    } catch (error) {
      console.error('Error handling drop:', error);
    }
  }
};
