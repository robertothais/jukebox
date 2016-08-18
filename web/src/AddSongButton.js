import React, { Component } from 'react';
import { Button } from 'react-bootstrap';
import AddSongModal from './AddSongModal'

class AddSongButton extends Component {
  constructor() {
    super();
    this.state = { showModal: false }
    this.open = this.open.bind(this)
    this.close = this.close.bind(this)
  }

  open() {
    this.setState({showModal: true})
  }

  close() {
    this.setState({showModal: false})
  }

  render() {
    return(
      <div>
        <button className='btn btn-danger navbar-btn add-button' onClick={this.open}>
          Add Your Song
          &nbsp;
          <i className='glyphicon glyphicon-music'/>
          </button>
        <AddSongModal show={this.state.showModal} close={this.close} />
      </div>
    )
  }
}

export default AddSongButton