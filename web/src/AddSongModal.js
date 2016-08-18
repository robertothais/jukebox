import React, { Component } from 'react';
import ReactDOM from 'react-dom';
import { Modal, Button, FormGroup, FormControl, HelpBlock } from 'react-bootstrap';
import SongTable from './SongTable'
import nextTick from 'browser-next-tick'
import VideoParser from 'js-video-url-parser'
import ToggleDisplay from 'react-toggle-display';
import superagent from 'superagent'
import jsonp from 'superagent-jsonp'

class AddSongModal extends Component {
  constructor() {
    super();
    this.handlePaste = this.handlePaste.bind(this)
    this.prepareInput = this.prepareInput.bind(this)
    this.addSong = this.addSong.bind(this)
    this.state = { valid: false, validationState: null, video: {} }
    window.receiveVideo = this.receiveVideo.bind(this)
  }

  handlePaste() {
    nextTick(() => {
      const video = VideoParser.parse(this.textInput.value)
      if (video && video.provider == 'youtube') {
        this.setState({validationState: 'success'})
        const url = VideoParser.create({videoInfo: video})
        superagent
          .get('https://noembed.com/embed')
          .query({url: url, callback: 'receiveVideo'})
          .use(jsonp)
          .end((err, res) => { })
      } else {
        this.setState({validationState: 'error', valid: false})
      }
    })
  }

  prepareInput(node) {
    this.textInput = ReactDOM.findDOMNode(node)
  }

  receiveVideo(data) {
    this.setState({video: data, valid: true, key: VideoParser.parse(data.url).id})
  }

  addSong() {
    const ref = firebase.database().ref(window.BUCKET)
    const song = this.state.video
    song['key'] = this.state.key
    song['votes'] = 1
    localStorage.setItem(song.key, 'up')
    ref.push(song, () => {
      this.props.close()
    })
  }

  render() {
    return(
      <Modal show={this.props.show} onHide={this.props.close}>
        <Modal.Header closeButton>
          Add Song from YouTube
        </Modal.Header>
        <Modal.Body>
          <form>
            <FormGroup bsSize='large' validationState={this.state.validationState}>
              <FormControl
                type="text"
                placeholder="Paste YouTube URL"
                onPaste={this.handlePaste}
                ref={this.prepareInput}
              />
              <FormControl.Feedback />
              <ToggleDisplay show={this.state.validationState != 'error'}>
                <HelpBlock>Tip: when searching for the video, add "HQ" at the end of your query to get a result with high quality audio.</HelpBlock>
              </ToggleDisplay>
              <ToggleDisplay show={this.state.validationState == 'error'}>
                <HelpBlock>Not a valid YouTube URL</HelpBlock>
              </ToggleDisplay>
            </FormGroup>
          </form>
          <ToggleDisplay show={this.state.valid}>
            <SongTable songs={[this.state.video]} />
          </ToggleDisplay>
        </Modal.Body>
        <Modal.Footer>
          <Button onClick={this.addSong} disabled={!this.state.valid} >Add!</Button>
        </Modal.Footer>
      </Modal>
    )
  }
}

export default AddSongModal