import React, { Component } from 'react';
import ToggleDisplay from 'react-toggle-display';
import { Modal } from 'react-bootstrap';

class SongThumbnail extends Component {

  constructor() {
    super();
    this.state = { hovering: false, embedHTML: null }
    this.onMouseEnter = this.onMouseEnter.bind(this)
    this.onMouseLeave = this.onMouseLeave.bind(this)
    this.playSong = this.playSong.bind(this)
    this.closeModal = this.closeModal.bind(this)
  }

  onMouseEnter() {
    this.setState({hovering: true})
  }

  onMouseLeave() {
    this.setState({hovering: false})
  }

  playSong() {
    this.setState({embedHTML: {__html: this.props.song.html}, showModal: true})
  }

  closeModal() {
    this.setState({embedHTML: null, showModal: false})
  }

  render() {
    return(
      <td onMouseEnter={this.onMouseEnter} onMouseLeave={this.onMouseLeave} onClick={this.playSong}>
        <img src={this.props.song.thumbnail_url} className='video-thumbnail' />
        <ToggleDisplay show={this.state.hovering} className='thumbnail-overlay-container'>
          <div className='thumbnail-overlay'>
            <i className='glyphicon glyphicon-play'/>
          </div>
        </ToggleDisplay>
        <Modal show={this.state.showModal} onHide={this.closeModal}>
          <Modal.Header closeButton>
            {this.props.song.title}
          </Modal.Header>
          <Modal.Body>
            <div dangerouslySetInnerHTML={this.state.embedHTML}/>
          </Modal.Body>
        </Modal>
      </td>
    );
  }
}

export default SongThumbnail