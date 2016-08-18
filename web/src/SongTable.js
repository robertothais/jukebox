import React, { Component } from 'react';
import SongThumbnail from './SongThumbnail'
import ToggleDisplay from 'react-toggle-display';
import _ from 'lodash'

class SongTable extends Component {

  constructor() {
    super();
    this.upvote = this.upvote.bind(this);
    this.downvote = this.downvote.bind(this);
  }

  upvote(uid, key) { return () => { this.vote(uid, key, 'up') } }

  downvote(uid, key) { return () => { this.vote(uid, key, 'down') } }

  vote(uid, key, direction) {
    if (!localStorage.getItem(key)) {
      const ref = firebase.database().ref(`${window.BUCKET}/${uid}`)
      ref.transaction( (song) => {
        if (song) {
          if (direction == 'up') {
            song.votes++
          } else if (direction == 'down') {
            song.votes--
          }
        }
        localStorage.setItem(key, direction)
        return song
      })
    }
  }

  render() {
    const that = this
    return(
      <table className='table'>
      <col className='video-thumbnail-col'/>
      <col/>
      <col className='votes-col'/>
        {_.map(this.props.songs, function(song) {
          return (<tr key={song.key}>
            <SongThumbnail song={song}/>
            <td><h4>{song.title}</h4></td>
            <td className={`votes ${localStorage.getItem(song.key) || 'none'}`}>
              <i className='glyphicon glyphicon-triangle-top' onClick={that.upvote(song.uid, song.key)}/>
              <h3>{song.votes}</h3>
              <i className='glyphicon glyphicon-triangle-bottom' onClick={that.downvote(song.uid, song.key)}/>
            </td>
          </tr>);
        })}
    </table>
    );
  }
}

export default SongTable