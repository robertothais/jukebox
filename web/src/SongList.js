import React, { Component } from 'react';
import SongTable from './SongTable'
import _ from 'lodash'

class SongList extends Component {
  constructor() {
    super();
    this.state = { songs: [] }
    this.ref = firebase.database().ref(window.BUCKET)
    this.ref.on('value', (snapshot) => {
      const val = snapshot.val()
      _.each(val, (song, uid) => { song.uid = uid })
      this.setState({songs: _.reverse(_.values(val))})
    })
  }

  render() {
    return (
      <div>
        <p className='text-right'>{this.state.songs.length} songs</p>
        <SongTable songs={this.state.songs}/>
      </div>
    );
  }
}

export default SongList;