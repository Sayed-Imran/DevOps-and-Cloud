import { useState, useEffect } from 'react';
import { Card, CardActionArea, CardMedia, CardContent, Typography } from '@mui/material';
import {faHeart, faX} from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

const ANIMAL_CATEGORIES = ['cats', 'dogs', 'fish', 'horse', 'rabbit', 'birds', 'cow'];

const CreateCards = ({
                         image = '',
                         alt = 'animal',
                         description = '',
                         likes = 0,
                         color = '',
                         handleOpenPopup = null,
                     }) => {
    const animal = [image, alt, description, likes, color, handleOpenPopup];
    // console.log(color);
    return(
        <Card className={`max-w-sm border b border-gray-200 rounded-xl shadow-md md:max-w-full max-h-min`} style={{backgroundColor: '#00042a'}} /*style={{backgroundColor: color}}*/>
            <CardActionArea onClick={() => handleOpenPopup(animal)}>
                <CardMedia
                    component="img"
                    className="h-48 w-full object-cover rounded-t-lg"
                    image={image}
                    alt={alt}
                />
                <CardContent className={`p-4 text-white`}>
                    <Typography gutterBottom variant="h5" component="div" className="">
                        {likes} <FontAwesomeIcon icon={faHeart} style={{color: "#e10e35"}} />
                    </Typography>
                    <Typography gutterBottom variant="h5" component="div" className={`overflow-hidden h-9`}>
                        {description}
                    </Typography>
                </CardContent>
            </CardActionArea>
        </Card>
    )
};

function App() {
    const [selectedCategory, setSelectedCategory] = useState('');
    const [animalData, setAnimalData] = useState([]);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState(null);
    const [selectedAnimal, setSelectedAnimal] = useState(null);
    const [isPopupOpen, setIsPopupOpen] = useState(false);
    const [refetch, setRefetch] = useState(true);


    const fetchAnimalData = async (category) => {
        setIsLoading(true);
        setError(null);

        try {
            const response = await fetch(`https://app.devopsguru.engineer/data/${category}`);
            const data = await response.json();
            setAnimalData(data);
        } catch (error) {
            console.error('Error fetching data:', error);
            setError(error.message);
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        if (selectedCategory) {
            fetchAnimalData(selectedCategory);
        }
    }, [selectedCategory, refetch]);

    const handleCategoryChange = (event) => {
        const category = ANIMAL_CATEGORIES.find((animal) => animal === event);
        if (category) {
            setSelectedCategory(category);
        }
        if (event.target && event.target.value) {
            setSelectedCategory(event.target.value);
        }
    };

    const handleOpenPopup = (animal) => {
        setSelectedAnimal(animal);
        setIsPopupOpen(true);
    };

    const handleClosePopup = () => {
        setIsPopupOpen(false);
    };

    const clicked = (e) => {
        e.preventDefault();
        if (e.target.id === 'popup') {
            handleClosePopup();
        }
    }

    useEffect(() => {
        handleCategoryChange(ANIMAL_CATEGORIES[Math.floor(Math.random() * ANIMAL_CATEGORIES.length)]);
    }, []);

    useEffect(() => {
        const handleEscapeKeyDown = (event) => {
            if (event.key === 'Escape') {
                handleClosePopup();
            }
        };

        document.addEventListener('keydown', handleEscapeKeyDown);

        return () => {
            document.removeEventListener('keydown', handleEscapeKeyDown);
        };
    }, []);

    return (
        <div className="container mx-auto px-4 py-8 duration-500">
            <h1 className="text-3xl font-bold text-center mb-8">Animal Album</h1>
            <div className={"flex 2xl:flex-row xl:flex-row lg:flex-row md:flex-row sm:flex-row flex-col justify-center 2xl:gap-x-4 xl:gap-x-4 lg:gap-x-4 md:gap-x-4 sm:gap-x-4 gap-y-4 mb-8"}>
                {ANIMAL_CATEGORIES.map((category) => (
                    <button
                        key={category}
                        className={`bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded duration-200`}
                        onClick={() => handleCategoryChange(category)}
                        disabled={isLoading}
                    >
                        {category.charAt(0).toUpperCase() + category.slice(1).toLowerCase()}
                    </button>
                ))}
            </div>
            {isLoading && <p className="text-center text-gray-500">Loading...</p>}
            {error && <p className="text-center text-red-500">Error: {error}</p>}
            {animalData.length > 0 && (
                <div className="grid min-h-screen max-h-max xs:grid-cols-1 sm:grid-cols-2 md:grid-cols-2 lg:grid-cols-4 gap-4 no-scrollbar overflow-y-scroll">
                    {animalData.map((animal) => (
                        <CreateCards
                            key={animal.id}
                            image={animal.image_url}
                            description={animal.description}
                            color={animal.color}
                            likes={animal.likes}
                            user={animal.user}
                            handleOpenPopup={() => handleOpenPopup(animal)}
                        />
                    ))}
                </div>
            )}
            {isPopupOpen && (
                <div className="fixed top-0 left-0 w-full h-full flex justify-center items-center bg-black bg-opacity-75" id={`popup`} onClick={clicked}>
                    <div className={`flex flex-col bg-[#F3BFB3] rounded-3xl overflow-y-scroll no-scrollbar md:w-1/2 lg:w-1/2 h-screen m-2 p-5`}>
                        <div className={`relative w-full align-middle justify-end p-0`}>
                            <div className={`absolute top-1 right-4 mr-0 -mr-1`}>
                                <button className={`font-bold text-3xl text-white outline-4 outline-black shadow-2xl`} style={{textShadow: "2px 2px 1px #000"}} onClick={handleClosePopup}>
                                    {/* As Fontawesome has svg box shadow cannot be applied */}
                                    {/*<div className={`absolute top-1 right-5 text-3xl text-white`}>
                                        <FontAwesomeIcon className={`font-bold text-3xl text-white outline-4 outline-black`} icon={faX} />
                                    </div>*/}
                                    X
                                </button>
                            </div>
                            <img src={selectedAnimal.image_url} className={'object-scale-down'} alt={selectedAnimal.alt}/>
                        </div>
                        <h2 className="text-xl font-bold mb-2">{selectedAnimal.description}</h2>
                        <Typography gutterBottom variant="h5" component="div" className="">
                            {selectedAnimal.likes} <FontAwesomeIcon icon={faHeart} style={{color: "#e10e35"}} />
                        </Typography>
                        <div>
                            <h3 className={`text-l mb-2`}><b>Name: </b>{selectedAnimal.user.name}</h3>
                            <h3 className={`text-l ${selectedAnimal.user.location !== 'null'?'':'hidden'} mb-2`}><b>Location: </b>{selectedAnimal.user.location}</h3>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}

export default App;