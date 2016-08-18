import React, { Component } from 'react';
import { Navbar, Nav } from 'react-bootstrap';
import AddSongButton from './AddSongButton'

class Navigation extends Component {
  render() {
    return(
      <Navbar>
        <Navbar.Header>
          <Navbar.Brand>
            <a href="#">Whynauts Jukebox Songs</a>
          </Navbar.Brand>
        </Navbar.Header>
        <Nav pullRight>
          <AddSongButton/>
        </Nav>
      </Navbar>
    )
  }
}

export default Navigation