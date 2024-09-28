import {useState} from "react";

export const Popup = ({
    description='',
    img='',
    user={},
    likes = 0
                      }) => {

    const [isPopupOpen, setIsPopupOpen] = useState(false);

    const handleOpenPopup = () => {
        setIsPopupOpen(true);
    };

    const handleClosePopup = () => {
        setIsPopupOpen(false);
    };

    return (
        <>
            <div className={'absolute hidden'}>
                <button onClick={handleOpenPopup}>Show
                    More
                </button>
                {isPopupOpen && (
                    <div
                        className="fixed top-0 left-0 w-full h-full flex justify-center items-center bg-black bg-opacity-75">
                        <div className="bg-white rounded-lg p-4">
                            <button className="absolute top-2 right-2 text-gray-500" onClick={handleClosePopup}>
                                &times;
                            </button>
                            {/*<h2 className="text-xl font-bold mb-2">{title === '' ? 'Cute' : title}</h2>*/}
                            <p className="text-gray-700">{description}</p>
                            {/* Add more details here */}
                        </div>
                    </div>
                )}
            </div>
        </>
    )
}
